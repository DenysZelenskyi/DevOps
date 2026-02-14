# Lesson 5 - Terraform AWS Infrastructure

Homework assignment from DevOps course - creating AWS infrastructure using Terraform.

## What Gets Created

This project deploys the following infrastructure:

- **VPC** with public and private subnets
- **S3 bucket** for storing Terraform state
- **DynamoDB table** for state locking
- **ECR repository** for Docker images
- **Internet Gateway** and **NAT Gateway** for network access

## Project Structure

```
lesson-5/
├── main.tf              # Main file with module connections
├── variables.tf         # Project variables
├── outputs.tf           # Output values
├── backend.tf           # S3 backend configuration
└── modules/             # Modules directory
    ├── s3-backend/      # Module for S3 + DynamoDB
    │   ├── s3.tf
    │   ├── dynamodb.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── vpc/             # Network infrastructure module
    │   ├── vpc.tf
    │   ├── routes.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── ecr/             # Module for Docker registry
        ├── ecr.tf
        ├── variables.tf
        └── outputs.tf
```

## Module Description

### s3-backend Module

**Purpose:** Creating infrastructure for storing Terraform state files.

**What it creates:**

- S3 bucket with versioning and encryption enabled
- DynamoDB table for state locking
- Security settings (blocking public access)

**Why it's needed:**  
This module is necessary for centralized storage of Terraform states. Thanks to S3 and DynamoDB, you can safely work with infrastructure in a team, avoiding conflicts during concurrent terraform apply executions.

### vpc Module

**Purpose:** Creating complete network infrastructure in AWS.

**What it creates:**

- VPC with specified CIDR block (default 10.0.0.0/16)
- 3 public subnets (with internet access)
- 3 private subnets (without direct internet access)
- Internet Gateway for public subnets
- NAT Gateway for internet access from private subnets
- Route Tables for routing configuration
- Elastic IP for NAT Gateway

**Variables:**

- `vpc_cidr` - CIDR block for VPC
- `public_subnets` - list of CIDR blocks for public subnets
- `private_subnets` - list of CIDR blocks for private subnets
- `availability_zones` - list of availability zones
- `enable_nat_gateway` - enable/disable NAT Gateway (default true)

**Why it's needed:**  
VPC creates an isolated network in AWS. Public subnets are used for resources that should be accessible from the internet (e.g., load balancer), while private subnets are for internal services (databases, application servers). NAT Gateway allows private subnets to access the internet for updates but doesn't accept incoming connections.

### ecr Module

**Purpose:** Creating Docker Container Registry for storing images.

**What it creates:**

- ECR repository with automatic image scanning
- Encryption settings (AES256)
- Lifecycle policy for automatic deletion of old images
- Repository policy for access control

**Why it's needed:**  
ECR is needed for storing Docker images of your applications. After creating the repository, you can upload images there and use them in services like ECS, EKS, or Lambda.

## Commands for Working

### Initialization and Deployment

**Step 1: AWS Configuration**

```bash
# Configure AWS credentials
aws configure
```

**Step 2: Creating S3 Backend**

Since the S3 bucket doesn't exist yet, we first create it with local state:

```bash
# Navigate to project directory
cd lesson-5

# Temporarily disable backend
mv backend.tf backend.tf.off

# Initialize Terraform without backend
terraform init -backend=false

# Create only S3 and DynamoDB
terraform apply -target=module.s3_backend -auto-approve
```

After executing the command, remember the name of the created S3 bucket from the output!

**Step 3: Connecting Remote Backend**

Update the `backend.tf.off` file - insert the correct bucket name, then:

```bash
# Restore backend.tf
mv backend.tf.off backend.tf

# Migrate state to S3
terraform init -migrate-state
# Enter "yes" when prompted
```

**Step 4: Deploying Full Infrastructure**

```bash
# View plan of changes
terraform plan

# Apply changes
terraform apply
```

Or automatically without confirmation:

```bash
terraform apply -auto-approve
```

### Checking Results

```bash
# View created resources
terraform output

# Check list of resources in state
terraform state list
```

### Destroying Infrastructure

```bash
# Delete all resources
terraform destroy

# Or automatically
terraform destroy -auto-approve
```

**Important:** S3 bucket may not be deleted automatically due to lifecycle policy. To delete it:

```bash
# First empty the bucket
aws s3 rm s3://your-bucket-name --recursive

# Then delete the bucket
aws s3 rb s3://your-bucket-name --force
```

### Troubleshooting

**Problem:** terraform init shows backend error  
**Solution:** Make sure backend.tf is disabled on first run

**Problem:** Can't delete NAT Gateway  
**Solution:** Wait a few minutes - AWS needs time to delete dependencies

**Problem:** State locking error  
**Solution:** Check that DynamoDB table is created
