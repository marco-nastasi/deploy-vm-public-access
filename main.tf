terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.43"
    }
  }
  cloud {
    organization = "marco-nastasi-org"
    hostname = "app.terraform.io"
    
    workspaces {
      name = "docker-playground"
    }
  }
}

provider "aws" {
  region  = var.region
}

resource "aws_vpc" "docker-playground" {
  cidr_block           = var.address_space
  enable_dns_hostnames = true

  tags = {
    name = "${var.prefix}-vpc-${var.region}"
    app = "${var.appname}"
  }
}

resource "aws_subnet" "docker-playground" {
  vpc_id     = aws_vpc.docker-playground.id
  cidr_block = var.subnet_prefix

  tags = {
    name = "${var.prefix}-subnet"
    app = "${var.appname}"
  }
}

resource "aws_security_group" "docker-playground" {
  name = "${var.prefix}-security-group"
  description = "Docker playground Security Group"
  vpc_id = aws_vpc.docker-playground.id

  ingress {
    description = "Allow HTTP traffic to port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.my_own_public_ip
  }

  ingress {
    description = "Allow HTTP traffic to port 8008"
    from_port   = 8008
    to_port     = 8008
    protocol    = "tcp"
    cidr_blocks = var.my_own_public_ip
  }

  ingress {
    description = "Allow HTTP traffic to port 8081"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = var.my_own_public_ip
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.prefix}-security-group"
    app = "${var.appname}"
  }
}

resource "aws_internet_gateway" "docker-playground" {
  vpc_id = aws_vpc.docker-playground.id

  tags = {
    Name = "${var.prefix}-internet-gateway"
    app = "${var.appname}"
  }
}

resource "aws_route_table" "docker-playground" {
  vpc_id = aws_vpc.docker-playground.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.docker-playground.id
  }

  tags = {
    Name = "${var.prefix}-route-table"
    app = "${var.appname}"
  }
}

resource "aws_route_table_association" "docker-playground" {
  subnet_id      = aws_subnet.docker-playground.id
  route_table_id = aws_route_table.docker-playground.id
}

data "aws_ami" "amazon-linux-2023" {
  most_recent = true

  filter {
    name = "name"
    values = ["al2023-ami-2023*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_iam_role" "docker-playground" {
  name = "Ec2InstanceRole"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "docker-playground" {
  name = "ec2instance-role"
  role = aws_iam_role.docker-playground.name

  tags = {
    Name = "${var.prefix}-iam-instance-profile"
    app = "${var.appname}"
  }
}

resource "aws_iam_role_policy_attachment" "amazon_ssm_managed_instance_core" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.docker-playground.name
}

resource "aws_instance" "docker-playground" {
  ami                         = data.aws_ami.amazon-linux-2023.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.docker-playground.id
  vpc_security_group_ids      = [aws_security_group.docker-playground.id]
  iam_instance_profile = aws_iam_instance_profile.docker-playground.name

  tags = {
    Name = "${var.prefix}-docker-playground-instance"
    app = "${var.appname}"
  }
  user_data = file("${path.module}/boot_script.sh")
}