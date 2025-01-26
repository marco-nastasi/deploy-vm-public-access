# Deploy EC2 instance with public access in AWS

## Description

This is a simple project that runs multiple containerized applications using Docker in a EC2 instance of AWS. The application itself is available in this repository: https://github.com/marco-nastasi/example-voting-app-monitored.

This project uses Github Actions to deploy resources to AWS using Terraform. The main parts are the Terraform code itself and the Github Actions workflows to validate, scan, plan, apply and destroy resources.

## Components

In this section you will find details about the main components of the project. Some design choices don't follow best practices, this is not production ready.

### AWS Infrastructure

- **VPC**: This is the virtual network where all the resources will be provisioned. The CIDR block is defined in Terraform in the variable `address_space`. The default value is `10.0.0.0/16`.
- **Public Subnet**: A VPC can contain one or more subnets. To simplify the deployment, a public subnet is used. The CIDR block of the subnet is contained in the CIDR block of the VPC, and its defined in the variable `subnet_prefix`. The default value is `10.0.10.0/24`.
- **Security Groups**:
  - *Ingress*: The instance only accepts incoming connections on ports 80, 8008 and 8081 from an specific IP address. The allowed IP address is configured as a Github Actions variable called `TF_VAR_MY_OWN_PUBLIC_IP`, and that value will be passed to the Terraform variable `my_own_public_ip`. There is no default value for security reasons.
  - *Egress*: No restrictions are configured for the outbound traffic from the EC2 instance.
- **Internet Gateway**: Allows traffic from and to the internet to the EC2 instance.
- **EC2 instance**: A EC2 instance