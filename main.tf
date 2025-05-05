terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  alias  = "ap-southeast-1"
  region = "ap-southeast-1"
  default_tags {
    tags = {
      Environment = "dev"
      Project     = "chatbot-app"
      ManagedBy   = "terraform"
    }
  }
}

module "vpc" {
  source         = "./modules/vpc"
  environment    = "prod"
  project_name   = "chatbot-app"
  vpc_cidr_block = "10.0.0.0/16"
  public_subnets = {
    "public-a" = { cidr_block = "10.0.0.0/20", availability_zone = "ap-southeast-1a" }
    "public-b" = { cidr_block = "10.0.16.0/20", availability_zone = "ap-southeast-1b" }
  }
  private_subnets = {
    "app-a" = { cidr_block = "10.0.48.0/20", availability_zone = "ap-southeast-1a" }
    "app-b" = { cidr_block = "10.0.64.0/20", availability_zone = "ap-southeast-1b" }
  }
}
