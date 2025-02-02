# Deploy EC2 instance with public access in AWS

## Description

This is a simple project that runs multiple containerized applications using Docker in a EC2 instance of AWS. The application itself is available in this repository: https://github.com/marco-nastasi/example-voting-app-monitored.

This project uses Github Actions to deploy resources to AWS using Terraform. The main parts are the Terraform code itself and the Github Actions workflows to validate, scan, plan, apply and destroy resources.

## Design principles

1) The Terraform state file is stored in a S3 bucket, which also uses a DynamoDB table for state locking. Following best practices, the S3 bucket and the DynamoDB table are not part of this project. They were created with the help of a Terraform module, available here: https://github.com/marco-nastasi/terraform-aws-s3-dynamodb-state.
2) The deployment and destruction of the resources in AWS is done through Github Actions workflows. The authentication is not done using permanent AWS Access Keys, instead Github is added as OIDC provider and temporary short lived credentials are used. This repo in the "main" branch is configured to be the trusted entity, IAM is configured to assign a least-access-privilege role that is only enough to deploy the resources contained in this project.
3) Thorough Security Scans are performed with Checkov to make sure that best practices are used.
4) The Terraform state file is considered a sensitive artifact, that's why it's not stored in Github but rather in a private S3 bucket that has encryption at rest.
5) There are special mechanisms to make sure that the resources deployed to AWS correspond to a previously created plan. The goal is to avoid surprises by adding unwanted resources, also avoiding replacements or changes in key elements.  

## How to deploy to AWS?

There are three Github Actions workflows that take care of the deployment. The first of the workflows (`terraform-plan.yml`) will automatically run when a commit is force-pushed or a PR is merged to the "main" branch. Additionally, it's also possible to execute it manually. Follow this order to deploy, simply click on Actions in this repo and execute:

1) 1 - Prepare Terraform plan
2) 2 - Deploy to AWS

If you don't need the infra anymore and wish to remove all resources, simply execute:

3) 3 - Remove from AWS

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

- **1 - Prepare Terraform plan**: Defined in `terraform-plan.yml`. It contains five jobs and it's executed when a Pull Request is merged or a push is made to the main branch:
  - *Terraform format check*: The goal of this job is to perform Terraform format checks with the command `terraform fmt`. If this job finds format changes that need to be made, it will fail and stop the pipeline. This job automatically runs when a commit is force-pushed or a PR is merged to the "main" branch. This job runs in parallel to *Validate Terraform code*.
  - *Validate Terraform code*: The goal of this job is to perform Terraform code validations with the command `terraform validate`. if this job finds issues, it will fail and stop the pipeline. This job automatically runs when a commit is force-pushed or a PR is merged to the "main" branch. This job runs in parallel to *Terraform format check* and *Lint Terraform code*.
  - *Lint Terraform code*: This job is executed the Action `tflint` and its goal is to identify potential problems, errors, unused variables, etc. This job runs in parallel to *Terraform format check* and *Validate Terraform code*. 
  - *Security Scan*: This job is executed using the Action `checkov` and its goal is to check how secure is the infrastructure to be deployed. A set of Security checks are performed to ensure that the best practices are strictly followed. If any recommendation is not followed the job will fail and stop the pipeline. This job runs after *Terraform format check* and *Validate Terraform code*.
  - *Create Terraform plan*: The goal of this job is to create a plan containing all the changes that need to be made to reach the defined state in the Terraform code. The plan may contain sensitive information, and that's why the plan file is not saved as an artifact, instead it's uploaded to the same S3 bucket where the Terraform state is stored. If the plan cannot be uploaded to the S3 bucket the job will fail and the pipeline will be stopped.

- **2 - Deploy plan to AWS**: Defined in `terraform-deploy.yml`. This workflow is not executed automatically, it needs a manual execution. It contains two jobs job:
  - *Check if valid plan exists*: The goal of this job is to check if the workflow "1 - Prepare Terraform plan" was successfully executed for this specific version of the application. It checks the status of the most recent execution of the workflow and the job fails if it was not successful. This check is made to make sure that the changes that will be implemented correspond to a valid plan.
  - *Terraform Apply*: The goal of this job is to apply the changes contained in the plan that was prepared by the workflow "1 - Prepare Terraform plan", The plan is downloaded from the S3 bucket and then applied.

- **3 - Remove from AWS**: Defined in `terraform-destroy.yml`. his workflow is not executed automatically, it needs a manual execution. It contains only one job:
  - *Terraform Destroy*: The goal of this job is to remove all provisioned resources from AWS. This is achieved by the execution of the command `terraform destroy -auto-approve`.