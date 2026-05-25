
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
  cidr_block = "10.16.16.0/28"
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
  cidr_block = "10.16.16.16/28"
  availability_zone = data.aws_availability_zones.available.names[1]

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