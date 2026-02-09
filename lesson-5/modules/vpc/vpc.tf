resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-vpc-igw"
    Environment = var.environment
  }
}

# Hardcoded subnets for simplicity
resource "aws_subnet" "public" {
  count = 3

  vpc_id                  = aws_vpc.main.id
  cidr_block              = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"][count.index]
  availability_zone       = ["us-east-1a", "us-east-1b", "us-east-1c"][count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-vpc-public-subnet-${count.index + 1}"
    Environment = var.environment
    Type        = "Public"
  }
}

# Private subnets
resource "aws_subnet" "private" {
  count = 3

  vpc_id            = aws_vpc.main.id
  cidr_block        = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"][count.index]
  availability_zone = ["us-east-1a", "us-east-1b", "us-east-1c"][count.index]

  tags = {
    Name        = "${var.environment}-vpc-private-subnet-${count.index + 1}"
    Environment = var.environment
    Type        = "Private"
  }
}

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  domain = "vpc"

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name        = "${var.environment}-vpc-eip"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name        = "${var.environment}-vpc-nat-gateway"
    Environment = var.environment
  }
}