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