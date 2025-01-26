##############################################################################
# Variables File
#
# Here is where we store the default values for all the variables used in our
# Terraform code. If you create a variable with no default, the user will be
# prompted to enter it (or define it via config file or command line flags.)

variable "environment" {
  description = "Environment of the app: Dev, Stage, Prod"
  type        = string
  default     = "Dev"
}

variable "appname" {
  description = "Name of the app"
  type        = string
  default     = "Docker_Playground"
}

variable "prefix" {
  description = "This prefix will be included in the name of most resources."
  type        = string
  default     = "docker_playground_"
}

variable "region" {
  description = "The region where resources will be deployed."
  type        = string
  default     = "eu-central-1"
}

variable "availability_zone" {
  description = "The availability zone where resources will be deployed."
  type        = string
  default     = "eu-central-1a"
}

variable "address_space" {
  description = "The CIDR of the Virtual Network."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_prefix" {
  description = "The address prefix to use for the subnet."
  type        = string
  default     = "10.0.10.0/24"
}

variable "instance_type" {
  description = "Specifies the AWS instance type."
  type        = string
  default     = "t2.micro"
}

variable "my_own_public_ip" {
  description = "Your public IP. It's used to allow connections from this IP only"
  type        = string
  sensitive   = true
}

variable "allowed_ports" {
  description = "List of ports that will be allowed from the public IP"
  type        = list(number)
  default     = [80, 8008, 8081]
}