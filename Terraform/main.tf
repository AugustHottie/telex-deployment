# VPC Module (assuming you're using the AWS VPC module)
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.63.0"
    }
  }
}

provider "aws" {
    region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "telex-cicd"
    key    = "telex-eks/terraform.tfstate"
    region = "us-east-1"
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  
  name = "telex-vpc"
  cidr = "10.0.0.0/16"
  
  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway = true
  
  tags = {
    terraform  = "true"
    Environment = "production"
    Project     = "telex"
  }
}