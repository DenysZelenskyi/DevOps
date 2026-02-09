# Lesson 5: Terraform AWS Infrastructure

Creating AWS infrastructure with Terraform using modules.

## What's Created

- S3 bucket for Terraform state
- VPC with public and private subnets
- ECR repository for Docker images
- DynamoDB table for state locking

## Setup

1. Configure AWS CLI:
```bash
aws configure
```

2. Deploy infrastructure:
```bash
cd lesson-5
terraform init
terraform plan
terraform apply
```

3. Enable S3 backend:
- Update `backend.tf` with the S3 bucket name from output
- Run `terraform init -migrate-state`

## Project Structure

```
lesson-5/
├── main.tf              # Main configuration
├── variables.tf         # Variables  
├── outputs.tf          # Outputs
├── backend.tf          # S3 backend setup
└── modules/
    ├── s3-backend/     # S3 + DynamoDB
    ├── vpc/            # VPC + subnets
    └── ecr/            # Container registry
```

## Cleanup

```bash
terraform destroy
```