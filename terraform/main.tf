terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ============================================
# VPC PUBLIC - Cho Frontend
# ============================================

resource "aws_vpc" "public_vpc" {
  cidr_block           = var.public_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Public-VPC-Frontend"
  }
}

resource "aws_internet_gateway" "public_igw" {
  vpc_id = aws_vpc.public_vpc.id

  tags = {
    Name = "Public-IGW"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.public_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-Frontend"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.public_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public_igw.id
  }

  tags = {
    Name = "Public-Route-Table"
  }
}

resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ============================================
# VPC PRIVATE - Cho Backend
# ============================================

resource "aws_vpc" "private_vpc" {
  cidr_block           = var.private_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Private-VPC-Backend"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.private_vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "Private-Subnet-Backend"
  }
}

# Elastic IP cho NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  depends_on = [aws_internet_gateway.private_igw]

  tags = {
    Name = "NAT-Gateway-EIP"
  }
}

# Internet Gateway cho Private VPC (cần thiết cho NAT Gateway)
resource "aws_internet_gateway" "private_igw" {
  vpc_id = aws_vpc.private_vpc.id

  tags = {
    Name = "Private-IGW"
  }
}

# NAT Gateway trong Public Subnet của Private VPC
resource "aws_subnet" "private_nat_subnet" {
  vpc_id                  = aws_vpc.private_vpc.id
  cidr_block              = var.private_nat_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "Private-NAT-Subnet"
  }
}

resource "aws_nat_gateway" "private_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.private_nat_subnet.id
  depends_on    = [aws_internet_gateway.private_igw]

  tags = {
    Name = "Private-NAT-Gateway"
  }
}

# Route Table cho Private Subnet (backend)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.private_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.private_nat.id
  }

  tags = {
    Name = "Private-Route-Table"
  }
}

resource "aws_route_table_association" "private_rta" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# Route Table cho NAT Subnet (public)
resource "aws_route_table" "private_nat_rt" {
  vpc_id = aws_vpc.private_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.private_igw.id
  }

  tags = {
    Name = "Private-NAT-Route-Table"
  }
}

resource "aws_route_table_association" "private_nat_rta" {
  subnet_id      = aws_subnet.private_nat_subnet.id
  route_table_id = aws_route_table.private_nat_rt.id
}

# ============================================
# VPC PEERING - Để Frontend và Backend giao tiếp
# ============================================

resource "aws_vpc_peering_connection" "public_to_private" {
  vpc_id      = aws_vpc.public_vpc.id
  peer_vpc_id = aws_vpc.private_vpc.id
  auto_accept = true

  tags = {
    Name = "Public-to-Private-Peering"
  }
}

# Route trong Public VPC để đi đến Private VPC
resource "aws_route" "public_to_private" {
  route_table_id            = aws_route_table.public_rt.id
  destination_cidr_block    = var.private_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.public_to_private.id
}

# Route trong Private VPC để đi đến Public VPC
resource "aws_route" "private_to_public" {
  route_table_id            = aws_route_table.private_rt.id
  destination_cidr_block    = var.public_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.public_to_private.id
}

# ============================================
# SECURITY GROUPS
# ============================================

# Security Group cho Frontend
resource "aws_security_group" "frontend_sg" {
  name        = "frontend-security-group"
  description = "Security group for frontend EC2 instance"
  vpc_id      = aws_vpc.public_vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Frontend-Security-Group"
  }
}

# Security Group cho Backend
resource "aws_security_group" "backend_sg" {
  name        = "backend-security-group"
  description = "Security group for backend EC2 instance"
  vpc_id      = aws_vpc.private_vpc.id

  ingress {
    description     = "Allow traffic from frontend on port 3000"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }

  ingress {
    description     = "Allow traffic from frontend on port 8000"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }

  ingress {
    description = "Allow traffic from Public VPC CIDR"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.public_vpc_cidr]
  }

  ingress {
    description = "Allow traffic from Public VPC CIDR on port 8000"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = [var.public_vpc_cidr]
  }

  ingress {
    description = "SSH from bastion or VPN"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Backend-Security-Group"
  }
}

# ============================================
# SSH KEY PAIR (Optional - uncomment if you have a public key)
# ============================================

# Uncomment và cập nhật đường dẫn đến public key của bạn
# resource "aws_key_pair" "deployer" {
#   key_name   = "deployer-key"
#   public_key = file("~/.ssh/id_rsa.pub")
# }
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# ============================================
# EC2 INSTANCES
# ============================================

# Frontend EC2 Instance (có Public IP)
resource "aws_instance" "frontend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  associate_public_ip_address = true
  # key_name               = aws_key_pair.deployer.key_name  # Uncomment nếu dùng key pair
  key_name = aws_key_pair.deployer.key_name

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx
              systemctl start nginx
              systemctl enable nginx
              EOF

  tags = {
    Name = "Frontend-Instance"
  }
}

# Backend EC2 Instance (không có Public IP)
resource "aws_instance" "backend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  associate_public_ip_address = false
  # key_name               = aws_key_pair.deployer.key_name  # Uncomment nếu dùng key pair
  key_name = aws_key_pair.deployer.key_name

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nodejs npm
              EOF

  tags = {
    Name = "Backend-Instance"
  }
}

# ============================================
# DATA SOURCES
# ============================================

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

