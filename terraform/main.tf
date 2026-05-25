# Configure Terraform to use the AWS provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-southeast-1"
}

module "networking" {
  source = "./networking"
}

module "compute" {
  source = "./compute"
}