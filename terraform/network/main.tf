# Create a VPC with a CIDR block of 10.16.16.0/24
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block = "10.16.16.0/24"

  tags = merge(
    local.common_tags,
    {
      Role = "network"
    }
  )
}

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