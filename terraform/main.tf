resource "aws_vpc" "docker_playground_vpc" {
  cidr_block           = var.address_space
  enable_dns_hostnames = true

  tags = local.tags
}

resource "aws_subnet" "docker_playground_priv_subnet" {
  vpc_id     = aws_vpc.docker_playground_vpc.id
  cidr_block = var.subnet_prefix

  tags = local.tags
}

resource "aws_security_group" "docker_playground_sg" {
  name        = "${var.prefix}-security-group"
  description = "Docker playground Security Group"
  vpc_id      = aws_vpc.docker_playground_vpc.id

  dynamic "ingress" {
    for_each = [80, 8008, 8081]
    iterator = port
    content {
      description = "Allow traffic from port ${port.value}"
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = var.my_own_public_ip
    }
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = local.tags
}

resource "aws_internet_gateway" "docker_playground" {
  vpc_id = aws_vpc.docker_playground_vpc.id

  tags = local.tags
}

resource "aws_route_table" "docker_playground" {
  vpc_id = aws_vpc.docker_playground_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.docker_playground.id
  }

  tags = local.tags
}

resource "aws_route_table_association" "docker_playground" {
  subnet_id      = aws_subnet.docker_playground_priv_subnet.id
  route_table_id = aws_route_table.docker_playground.id
}

data "aws_ami" "ubuntu_2204" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_iam_role" "docker_playground" {
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

  tags = local.tags
}

resource "aws_iam_instance_profile" "docker_playground" {
  name = "ec2instance-role"
  role = aws_iam_role.docker_playground.name

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "amazon_ssm_managed_instance_core" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.docker_playground.name
}

resource "aws_instance" "docker_playground" {
  ami                         = data.aws_ami.ubuntu_2204.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.docker_playground_priv_subnet.id
  vpc_security_group_ids      = [aws_security_group.docker_playground_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.docker_playground.name

  tags = local.tags

  root_block_device {
    tags = local.tags
  }
  user_data = file("${path.module}./scripts/boot_script.sh")
}

locals {
  tags = {
    Service     = "${var.appname}"
    Environment = "${var.environment}"
  }
}