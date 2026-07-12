
data "aws_availability_zones" "available" {
  state = "available"
}

# Create a VPC with a CIDR block of 10.16.16.0/24
resource "aws_vpc" "main" {
  cidr_block = "10.16.16.0/24"

  tags = merge(
    var.common_tags,
    {
      Role = "network"
    }
  )
}

### Public Network ###

# Create public subnet with public IP mapping enabled
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.16.16.0/26"
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  
  tags = merge(
    var.common_tags,
    {
      Role = "network"
    }
  )
}

# Create internet gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Role = "network"
    }
  )  
}

# Create an Elastic IP for the NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = merge(
    var.common_tags,
    {
      Role = "network"
    }
  )
}

#Create NAT Gateway
resource "aws_nat_gateway" "main_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  tags = merge(
    var.common_tags,
    {
      Role = "network"
    }
  )

  # To ensure proper ordering, here's an explicit dependency on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main_igw]
}

# Create route table for any subnet with default route to Internet Gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = merge(
    var.common_tags,
    {
      Role = "network"
    }
  )
}

# Associate the public subnet with the public route table
resource "aws_route_table_association" "public_assoc" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

### Private Network ###

# Create private subnet without public IP mapping
resource "aws_subnet" "private" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.16.16.64/26"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(
    var.common_tags,
    {
      Role = "network"
    }
  )
}

# Create route table for any subnet with default route to NAT Gateway
resource "aws_route_table" "nat_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main_nat.id
  }

  tags = merge(
    var.common_tags,
    {
      Role = "network"
    }
  )
}

# Associate the private subnet with the NAT route table
resource "aws_route_table_association" "private_assoc" {
  subnet_id = aws_subnet.private.id
  route_table_id = aws_route_table.nat_rt.id
}

### Security Groups ###

# Create security group for bastion host
resource "aws_security_group" "bastion_sg" {
  name        = "bastion_sg"
  description = "Allow SSH access and TLS traffic to the bastion host, allow all outbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Role = "network"
    }
  )
}

# Allow SSH access from anywhere to the bastion host
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# Allow all outbound traffic from the bastion host
resource "aws_vpc_security_group_egress_rule" "bastion_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # all ports
}

# Create security group for common use by all nodes in the private subnet
resource "aws_security_group" "common_sg" {
  name        = "common_sg"
  description = "Allow SSH from bastion host, allow all outbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Role = "network"
    }
  )
}

# Allow SSH access from bastion host to any node in the private subnet
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_from_bastion_ipv4" {
  security_group_id = aws_security_group.common_sg.id
  referenced_security_group_id = aws_security_group.bastion_sg.id
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# Allow all outbound traffic from any node in the private subnet
resource "aws_vpc_security_group_egress_rule" "common_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.common_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # all ports
}

# Create security group for HAproxy load balancer
resource "aws_security_group" "haproxy_sg" {
  name        = "haproxy_sg"
  description = "Allow traffic from k3s nodes to HAproxy load balancer"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Role = "network"
    }
  )
}

# Create security group for k3s master nodes
resource "aws_security_group" "k3s_master_sg" {
  name        = "k3s_master_sg"
  description = "Allow traffic from k3s nodes and postgres to k3s master"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Role = "network"
    }
  )
}

# Create security group for k3s worker nodes
resource "aws_security_group" "k3s_worker_sg" {
  name        = "k3s_worker_sg"
  description = "Allow traffic from k3s nodes to k3s worker"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Role = "network"
    }
  )
}

# Create security group for postgres database
resource "aws_security_group" "postgres_sg" {
  name        = "postgres_sg"
  description = "Allow traffic from k3s nodes to postgres database"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Role = "network"
    }
  )
}

# Create security group for haproxy_keepalived instance
resource "aws_security_group" "haproxy_keepalived_sg" {
  name        = "haproxy_keepalived_sg"
  description = "Allow traffic from k3s nodes to HAproxy and Keepalived"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Role = "network"
    }
  )
}