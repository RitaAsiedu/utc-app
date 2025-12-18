# main.tf - SIMPLE VERSION

# VPC
resource "aws_vpc" "utc_vpc" {
  cidr_block = "10.10.0.0/16"
  tags = { Name = "utc-vpc", env = "dev", team = "config management" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.utc_vpc.id
  tags = { Name = "utc-igw", env = "dev", team = "config management" }
}

# Public Subnets (3 AZs)
resource "aws_subnet" "public" {
  count = 3
  vpc_id = aws_vpc.utc_vpc.id
  cidr_block = "10.10.${count.index + 1}.0/24"
  availability_zone = ["us-east-1a", "us-east-1b", "us-east-1c"][count.index]
  map_public_ip_on_launch = true
  tags = { Name = "utc-public-${["a", "b", "c"][count.index]}", env = "dev" }
}

# Private Subnets (6 total, 2 per AZ)
resource "aws_subnet" "private" {
  count = 6
  vpc_id = aws_vpc.utc_vpc.id
  cidr_block = "10.10.${count.index + 11}.0/24"
  availability_zone = ["us-east-1a", "us-east-1a", "us-east-1b", "us-east-1b", "us-east-1c", "us-east-1c"][count.index]
  tags = { Name = "utc-private-${["a", "a", "b", "b", "c", "c"][count.index]}", env = "dev" }
}

