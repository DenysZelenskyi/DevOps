terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  bucket_name = "${var.student_name}-terraform-state-${random_string.bucket_suffix.result}"
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

module "s3_backend" {
  source = "./modules/s3-backend"
  
  bucket_name = local.bucket_name
  table_name  = var.dynamodb_table_name
  environment = var.environment
}

module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr    = var.vpc_cidr
  environment = var.environment
}

module "ecr" {
  source = "./modules/ecr"
  
  environment = var.environment
}