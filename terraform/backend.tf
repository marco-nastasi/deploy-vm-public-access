terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "> 5.43"
    }
  }

  cloud {
    organization = "marco-nastasi-org"
    hostname     = "app.terraform.io"
    workspaces {
      name = "docker-playground"
    }
  }
}