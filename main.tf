terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.66"
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
    environment = "Production"
  }
}

resource "aws_subnet" "docker-playground" {
  vpc_id     = aws_vpc.docker-playground.id
  cidr_block = var.subnet_prefix

  tags = {
    name = "${var.prefix}-subnet"
  }
}

resource "aws_security_group" "docker-playground" {
  name = "${var.prefix}-security-group"
  description = "Allow SSH traffic from public IP"
  vpc_id = aws_vpc.docker-playground.id

  ingress {
    from_port   = 22
    to_port     = 22
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
  }
}

resource "aws_internet_gateway" "docker-playground" {
  vpc_id = aws_vpc.docker-playground.id

  tags = {
    Name = "${var.prefix}-internet-gateway"
  }
}

resource "aws_route_table" "docker-playground" {
  vpc_id = aws_vpc.docker-playground.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.docker-playground.id
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
}

resource "aws_iam_role_policy_attachment" "amazon_ssm_managed_instance_core" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.docker-playground.name
}

resource "aws_instance" "docker-playground" {
  ami                         = data.aws_ami.amazon-linux-2023.id
  instance_type               = var.instance_type
  #key_name                    = aws_key_pair.docker-playground.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.docker-playground.id
  vpc_security_group_ids      = [aws_security_group.docker-playground.id]
  iam_instance_profile = aws_iam_instance_profile.docker-playground.name

  tags = {
    Name = "${var.prefix}-docker-playground-instance"
  }
  user_data = file("${path.module}/boot_script.sh")
}

#resource "tls_private_key" "docker-playground" {
#  algorithm = "RSA"
#  rsa_bits  = 4096
#}

#locals {
#  private_key_filename = "${var.prefix}-ssh-key.pem"
#}

#resource "aws_key_pair" "docker-playground" {
#  key_name   = local.private_key_filename
#  public_key = tls_private_key.docker-playground.public_key_openssh

#  provisioner "local-exec" { # Create a "myKey.pem" to your computer!!
#    command = "echo '${tls_private_key.docker-playground.private_key_pem}' > '${var.private_key_path}'"
#  }
#}
