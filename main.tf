# Create a VPC with CIDR configured in variable address_space
resource "aws_vpc" "vpc" {
  # Skip specific security scan policies
  #checkov:skip=CKV2_AWS_11:DEV ENV does not need VPC flow logging
  cidr_block = var.address_space

  enable_dns_hostnames = true

  tags = merge(
    local.tags,
    {
      Name = "${var.environment}/${var.appname}/VPC"
    },
  )
}

# Create default security group that restricts all traffic
resource "aws_default_security_group" "default_sg" {
  vpc_id = aws_vpc.vpc.id
}

# Create a public subnet inside the VPC using the CIDR configured in subnet_prefix
resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = var.availability_zone
  cidr_block        = var.subnet_prefix

  tags = merge(
    local.tags,
    {
      Name = "${var.environment}/${var.appname}/PublicSubnet"
    },
  )
}

# Create a Security Group for the app
resource "aws_security_group" "sg" {
  name        = "${var.prefix}-security-group"
  description = "${var.appname} Security Group"
  vpc_id      = aws_vpc.vpc.id

  tags = merge(
    local.tags,
    {
      Name = "${var.environment}/${var.appname}/SecurityGroup"
    },
  )
}

# Create Ingress Rules for Security Group
resource "aws_vpc_security_group_ingress_rule" "ingress_rule" {
  count = length(var.allowed_ports)

  description       = "Allow from ${var.my_own_public_ip} to port ${var.allowed_ports[count.index]}"
  security_group_id = aws_security_group.sg.id

  cidr_ipv4 = var.my_own_public_ip

  # Allow traffic to ports in variable "allowed ports" 
  from_port   = var.allowed_ports[count.index]
  ip_protocol = "tcp"
  to_port     = var.allowed_ports[count.index]

  tags = merge(
    local.tags,
    {
      Name = "${var.environment}/${var.appname}/SGIngressRules"
    },
  )
}

# Create Egress Rules for the Security Group
resource "aws_vpc_security_group_egress_rule" "egress_rule" {
  description       = "Allow all outgoing traffic"
  security_group_id = aws_security_group.sg.id

  # Allow all TCP and UDP outgoing traffic from the EC2 instance
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  tags = merge(
    local.tags,
    {
      Name = "${var.environment}/${var.appname}/SGEgressRule"
    },
  )
}

# Define Internet Gateway to allow connectivity to/from Internet
resource "aws_internet_gateway" "i-gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    local.tags,
    {
      Name = "${var.environment}/${var.appname}/I-Gateway"
    },
  )
}

# Define Routing Table for the VPC
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.i-gateway.id
  }

  tags = merge(
    local.tags,
    {
      Name = "${var.environment}/${var.appname}/RouteTable"
    },
  )
}

# Associate route table to the public VPC
resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route_table.id
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
resource "aws_iam_role" "iam_role" {
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
      Name = "${var.environment}/${var.appname}/EC2IAMRole"
    },
  )
}

# Create AWS IAM Instance profile
resource "aws_iam_instance_profile" "ec2_role" {
  name = "IAMEC2InstanceProfile"
  role = aws_iam_role.iam_role.name

  tags = merge(
    local.tags,
    {
      Name = "${var.environment}/${var.appname}/EC2InstanceProfile"
    },
  )
}

# Attach policy to manage the EC2 instance via SSM
resource "aws_iam_role_policy_attachment" "iam_role_policy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.iam_role.name
}

# Create EC2 instance using the user data script
resource "aws_instance" "ec2_instance" {
  ami           = data.aws_ami.ubuntu_2204.id
  instance_type = var.instance_type

  # Skip specific security scan policies
  #checkov:skip=CKV_AWS_88:The SG only allows connections from one host
  #checkov:skip=CKV_AWS_126:DEV ENV does not require detailed monitoring

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # EC2 instance will have a public IP in the most basic deployment of the app
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.subnet.id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_role.name
  ebs_optimized               = true

  tags = merge(
    local.tags,
    {
      Name = "${var.environment}/${var.appname}/EC2Instance"
    },
  )

  root_block_device {
    tags = merge(
      local.tags,
      {
        Name = "${var.environment}/${var.appname}/DockerPlayground-EBSVolume"
      },
    )
  }

  user_data = file("scripts/boot_script.sh")
}

# Define tags for all resources
locals {
  tags = {
    Service     = "${var.appname}"
    Environment = "${var.environment}"
  }
}