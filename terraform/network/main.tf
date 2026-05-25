
data "aws_availability_zones" "available" {
  state = "available"
}

# Create a VPC with a CIDR block of 10.16.16.0/24
resource "aws_vpc" "main" {
  cidr_block = "10.16.16.0/24"

  tags = merge(
    local.common_tags,
    {
      Role = "network"
    }
  )
}

# Create public subnet with public IP mapping enabled
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.16.16.0/26"
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  
  tags = merge(
    local.common_tags,
    {
      Role = "network"
    }
  )
}

# Create private subnet without public IP mapping
resource "aws_subnet" "private" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.16.16.64/26"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(
    local.common_tags,
    {
      Role = "network"
    }
  )
}

# Create internet gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
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
    local.common_tags,
    {
      Role = "network"
    }
  )

  # To ensure proper ordering, here's an explicit dependency on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main_igw]
}

# Create an Elastic IP for the NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Role = "network"
    }
  )
}