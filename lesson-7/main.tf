terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
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

  vpc_cidr           = var.vpc_cidr
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
  enable_nat_gateway = var.enable_nat_gateway
  environment        = var.environment
}

module "eks" {
  source = "./modules/eks"

  cluster_name       = var.cluster_name
  cluster_version    = var.cluster_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  environment        = var.environment
}

module "ecr" {
  source = "./modules/ecr"

  environment = var.environment
}

# Configure kubectl
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--region",
      var.aws_region
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name,
        "--region",
        var.aws_region
      ]
    }
  }
}

# Jenkins module
module "jenkins" {
  source = "./modules/jenkins"

  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_certificate_authority_data
  oidc_issuer_url        = module.eks.oidc_issuer_url
  ecr_repository_url     = module.ecr.repository_url
  aws_region             = var.aws_region
  jenkins_admin_password = var.jenkins_admin_password
  github_token           = var.github_token
  helm_charts_repo_url   = var.django_app_repo_url
}

# Argo CD module
module "argo_cd" {
  source = "./modules/argo_cd"

  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_certificate_authority_data
  aws_region             = var.aws_region
  django_app_repo_url    = var.django_app_repo_url
  django_app_path        = var.django_app_path
}

# Monitoring module (Prometheus + Grafana)
module "monitoring" {
  source = "./modules/monitoring"

  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_certificate_authority_data
  aws_region             = var.aws_region
  grafana_admin_password = var.grafana_admin_password
  environment            = var.environment
}

# RDS module
module "rds" {
  source = "./modules/rds"

  identifier     = var.rds_identifier
  use_aurora     = var.use_aurora
  engine         = var.rds_engine
  engine_version = var.rds_engine_version
  instance_class = var.rds_instance_class
  multi_az       = var.rds_multi_az

  allocated_storage = var.rds_allocated_storage
  db_name           = var.rds_db_name
  db_username       = var.rds_db_username
  db_password       = var.rds_db_password

  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  allowed_cidr_blocks = [var.vpc_cidr]

  skip_final_snapshot = true
  deletion_protection = false
  environment         = var.environment
}
