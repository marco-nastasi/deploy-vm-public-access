# Deploy EC2 instance with public access in AWS

## Description

This is a simple project that runs multiple containerized applications using Docker in a EC2 instance of AWS. The application itself is available in this repository: https://github.com/marco-nastasi/example-voting-app-monitored.

This project uses Github Actions to deploy resources to AWS using Terraform. The main parts are the Terraform code itself and the Github Actions workflows to validate, scan, plan, apply and destroy resources.

## Components

In this section you will find details about the main components of the project. Some design choices don't follow best practices, this is not production ready.

### AWS Infrastructure

- **VPC**: This is the virtual network where all the resources will be provisioned. The CIDR block is defined in Terraform in the variable `address_space`. The default value is `10.0.0.0/16`.
- **Public Subnet**: A VPC can contain one or more subnets. To simplify the deployment, a public subnet is deployed in the availability zone specified in the Terraform variable `availability_zone`. The CIDR block of the subnet is contained in the CIDR block of the VPC, and its defined in the variable `subnet_prefix`. The default value is `10.0.10.0/24`.
- **Security Groups**:
  - *Ingress*: The instance only accepts incoming connections on ports 80, 8008 and 8081 from an specific IP address. The allowed IP address is configured as a Github Actions variable called `TF_VAR_MY_OWN_PUBLIC_IP`, and that value will be passed to the Terraform variable `my_own_public_ip`. There is no default value for security reasons.
  - *Egress*: No restrictions are configured for the outbound traffic from the EC2 instance.
- **Internet Gateway**: Allows traffic from and to the internet to the EC2 instance.
- **EC2 instance**: This is the VM where the APP is deployed. The type is defined in the Terraform variable `instance_type`. By default it's a `t2.micro`, which is the one offered in the first year of the AWS Free Tier. The OS of the VM is the latest release of Ubuntu 22.04 Server, which is also included in the AWS Free Tier. A cloud init script is part of the deployment, it's located inside the `scripts` folder. This VM will have a private IP address in the CIDR block of the Public Subnet, as well as a public IP address assigned by AWS when the instance is started.

### Github Actions Workflows

There are three reusable workflows in this project, located in the `.github/workflows` folder:

- **1 - Prepare Terraform plan**: Defined in `terraform-plan.yml`. It contains four jobs:
  - *Terraform format check*: The goal of this job is to perform Terraform format checks with the command `terraform fmt`. If this job finds format changes that need to be made, it will fail and stop the pipeline. This job automatically runs when a commit is force-pushed or a PR is merged to the "main" branch. This job runs in parallel to *Validate Terraform code*.
  - *Validate Terraform code*: The goal of this job is to perform Terraform code validations with the command `terraform validate`. if this job finds issues, it will fail and stop the pipeline. This job automatically runs when a commit is force-pushed or a PR is merged to the "main" branch. This job runs in parallel to *Terraform format check*.
  - *Security Scan*: This job is executed using the Action `checkov` and its goal is to check how secure is the infrastructure to be deployed. A set of Security checks are performed to ensure that the best practices are strictly followed. If any recommendation is not followed the job will fail and stop the pipeline. This job runs after *Terraform format check* and *Validate Terraform code*.
  - *Create Terraform plan*: The goal of this job is to create a plan containing all the changes that need to be made to reach the defined state in the Terraform code. The plan may contain sensitive information, and that's why the plan file is not saved as an artifact, instead it's uploaded to the same S3 bucket where the Terraform state is stored. If the plan cannot be uploaded to the S3 bucket the job will fail and the pipeline will be stopped.

- **2 - Deploy plan to AWS**: Defined in the `terraform-deploy.yml`. This workflow is not executed automatically, it needs a manual execution. It contains two jobs job:
  - *Check if valid plan exists*: The goal of this job is to check if the workflow **1 - Prepare Terraform plan** was successfully executed for this specific version of the application. It checks the status of the most recent execution of the workflow and fails if it was not successful. This check is made to make sure that the changes that will be implemented correspond to a valid plan.