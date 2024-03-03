provider "aws" {
  alias = "eu"
  region = "eu-central-1"
}

#Create VPC
resource "aws_vpc" "dev" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = {
    Name = "dev"
  }
}

#Create first public subnet in dev-vpc
resource "aws_subnet" "dev-public-1" {
  vpc_id                  = aws_vpc.dev.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "eu-central-1a"

  tags = {
    Name = "dev-public-1"
  }
}

#Create second public subnet in dev-vpc
resource "aws_subnet" "dev-public-2" {
  vpc_id                  = aws_vpc.dev.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "eu-central-1b"

  tags = {
    Name = "dev-public-2"
  }
}

#Create internet gateway for vpc
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.dev.id

  tags = {
    Name = "dev"
  }
}

#Create route tables for Internet gateway
resource "aws_route_table" "dev-public" {
  vpc_id = aws_vpc.dev.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "dev-public-1"
  }
}

#Create route associations public subnets
#1
resource "aws_route_table_association" "dev-public-1-a" {
  subnet_id      = aws_subnet.dev-public-1.id
  route_table_id = aws_route_table.dev-public.id
}

#2
resource "aws_route_table_association" "dev-public-2-a" {
  subnet_id      = aws_subnet.dev-public-2.id
  route_table_id = aws_route_table.dev-public.id
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
}

resource "aws_key_pair" "aws_key" {
  key_name   = "ansible-ssh-key"
  public_key = tls_private_key.key.public_key_openssh
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH traffic"
  vpc_id      = aws_vpc.dev.id
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.dev.id
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
}

resource "aws_instance" "server" {
  count                       = var.instance_count
  ami                         = var.ami
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.aws_key.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.dev-public-1.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id, aws_security_group.allow_http.id]

  tags = {
    Name = element(var.instance_tags, count.index)
  }
}

resource "aws_instance" "server-1" {
  count                       = var.instance_count
  ami                         = var.ami
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.aws_key.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.dev-public-2.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id, aws_security_group.allow_http.id]

  tags = {
    Name = element(var.instance_tags, count.index)
  }
}