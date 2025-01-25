# Docker Playground in AWS - The most basic solution

## Description
This is a simple project that runs multiple containerized applications using Docker in a EC2 instance of AWS. The application itself is available in this repository: https://github.com/marco-nastasi/example-voting-app-monitored

This project uses Github Actions to deploy resources to AWS using Terraform. The main parts are the Terraform code itself and the Github Actions workflows to validate, scan, plan, apply and destroy resources.

## Components
In this section you will find details about the main components of the project. Some design choices don't follow best practices, this is not production ready.

### AWS Infrastructure
- **VPC**: This is the virtual network where all the resources will be provisioned.
- **Subnet**: A VPC can contain one or more subnets. To simplify the deployment, a public subnet is used.
- **Security Groups**: 