##############################################################################
# Variables File
#
# Here is where we store the default values for all the variables used in our
# Terraform code. If you create a variable with no default, the user will be
# prompted to enter it (or define it via config file or command line flags.)

variable "environment" {
  description = "Environment of the app: Dev, Stage, Prod"
  default     = "Dev"
}

variable "appname" {
  description = "Name of the app"
  default     = "Docker_Playground"
}

variable "prefix" {
  description = "This prefix will be included in the name of most resources."
  default     = "docker_playground_"
}

variable "region" {
  description = "The region where the resources are created."
  default     = "eu-central-1"
}

variable "address_space" {
  description = "The address space that is used by the virtual network. You can supply more than one address space. Changing this forces a new resource to be created."
  default     = "10.0.0.0/16"
}

variable "subnet_prefix" {
  description = "The address prefix to use for the subnet."
  default     = "10.0.10.0/24"
}

variable "instance_type" {
  description = "Specifies the AWS instance type."
  default     = "t2.micro"
}

variable "my_own_public_ip" {
  description = "Your public IP"
}

variable "allowed_ports" {
  description = "List of ports that will be allowed from the public IP"
  default     = [80, 8008, 8081]
}
