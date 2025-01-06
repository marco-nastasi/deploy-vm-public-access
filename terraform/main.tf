# Create a VPC with CIDR configured in variable address_space
resource "aws_vpc" "docker_playground_vpc" {
  cidr_block           = var.address_space
  enable_dns_hostnames = true

  tags = merge(
    local.tags,
    {
      Name = "${var.appname}/${var.environment}/DockerPlayground-VPC"
    },
  )
}

# Create a public subnet inside the VPC using the CIDR configured in subnet_prefix
resource "aws_subnet" "docker_playground_public_subnet" {
  vpc_id     = aws_vpc.docker_playground_vpc.id
  cidr_block = var.subnet_prefix

  tags = merge(
    local.tags,
    {
      Name = "${var.appname}/${var.environment}/DockerPlayground-PublicSubnet"
    },
  )
}

# Create a Security Group for the containerized app
resource "aws_security_group" "docker_playground_sg" {
  name        = "${var.prefix}-security-group"
  description = "Docker playground Security Group"
  vpc_id      = aws_vpc.docker_playground_vpc.id

  # Iterate through list of allowed ports from my public IP address only
  dynamic "ingress" {
    for_each = [80, 8008, 8081, 3389]
    iterator = port
    content {
      description = "Allow traffic from port ${port.value}"
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = var.my_own_public_ip
    }
  }
  
  # Allow outgoing traffic everywhere
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = merge(
    local.tags,
    {
      Name = "${var.appname}/${var.environment}/DockerPlayground-SecurityGroup"
    },
  )

}

# Define Internet Gateway to allow connectivity from my public IP address
resource "aws_internet_gateway" "docker_playground" {
  vpc_id = aws_vpc.docker_playground_vpc.id

  tags = local.tags
}

# Define Routing Table for the VPC
resource "aws_route_table" "docker_playground" {
  vpc_id = aws_vpc.docker_playground_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.docker_playground.id
  }

  tags = merge(
    local.tags,
    {
      Name = "${var.appname}/${var.environment}/DockerPlayground-RouteTable"
    },
  )
}

# Associate route table to the public VPC
resource "aws_route_table_association" "docker_playground" {
  subnet_id      = aws_subnet.docker_playground_public_subnet.id
  route_table_id = aws_route_table.docker_playground.id
}

# Find latest AMI ID of Ubuntu 22.04
data "aws_ami" "ubuntu_2204" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

# Create IAM Role to be assumed by the EC2 instance
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

  tags = merge(
    local.tags,
    {
      Name = "${var.appname}/${var.environment}/DockerPlayground-EC2IAMRole"
    },
  )
}

# Create AWS IAM Instance profile
resource "aws_iam_instance_profile" "docker_playground" {
  name = "ec2instance-role"
  role = aws_iam_role.docker_playground.name

  tags = merge(
    local.tags,
    {
      Name = "${var.appname}/${var.environment}/DockerPlayground-EC2InstanceProfile"
    },
  )
}

# Attach policy to manage the EC2 instance via SSM
resource "aws_iam_role_policy_attachment" "amazon_ssm_managed_instance_core" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.docker_playground.name
}

# Create EC2 instance using the user data script
resource "aws_instance" "docker_playground" {
  ami                         = data.aws_ami.ubuntu_2204.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.docker_playground_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.docker_playground_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.docker_playground.name

  tags = merge(
    local.tags,
    {
      Name = "${var.appname}/${var.environment}/DockerPlayground-EC2Instance"
    },
  )

  root_block_device {
    tags = merge(
    local.tags,
    {
      Name = "${var.appname}/${var.environment}/DockerPlayground-EBSVolume"
    },
  )
  }

  user_data = file("../scripts/boot_script.sh")
}

# Define tags for all resources
locals {
  tags = {
    Service     = "${var.appname}"
    Environment = "${var.environment}"
  }
}