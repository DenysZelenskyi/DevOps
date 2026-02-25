# Infrastructure for Django Application on EKS

This project uses Terraform to create the necessary infrastructure in AWS for running a Django application on a Kubernetes (EKS) cluster. The infrastructure includes VPC, ECR repository for Docker images, and EKS cluster. The application is deployed using a Helm chart.

## Project Structure

```
lesson-7/
│
├── main.tf                  # Main file for connecting modules
├── backend.tf               # Backend configuration for state (S3 + DynamoDB)
├── outputs.tf               # Resource outputs
│
├── modules/                 # Directory with all modules
│   ├── s3-backend/          # Module for S3 and DynamoDB
│   │   ├── s3.tf            # S3 bucket creation
│   │   ├── dynamodb.tf      # DynamoDB creation
│   │   ├── variables.tf     # Variables for S3
│   │   └── outputs.tf       # Outputs for S3 and DynamoDB
│   │
│   ├── vpc/                 # Module for VPC
│   │   ├── vpc.tf           # VPC, subnets, Internet Gateway creation
│   │   ├── routes.tf        # Routing configuration
│   │   ├── variables.tf     # Variables for VPC
│   │   └── outputs.tf  
│   │
│   ├── ecr/                 # Module for ECR
│   │   ├── ecr.tf           # ECR repository creation
│   │   ├── variables.tf     # Variables for ECR
│   │   └── outputs.tf       # Repository URL output
│   │
│   └── eks/                 # Module for Kubernetes cluster
│       ├── eks.tf           # Cluster creation
│       ├── variables.tf     # Variables for EKS
│       └── outputs.tf       # Cluster information output
│
└── charts/
    └── django-app/
        ├── templates/
        │   ├── deployment.yaml
        │   ├── service.yaml
        │   ├── configmap.yaml
        │   ├── secret.yaml
        │   └── hpa.yaml
        ├── Chart.yaml
        └── values.yaml      # Configuration with environment variables and secrets
```

## Deployment Steps

### 1. Initialize and Apply Terraform

First, initialize Terraform to download the necessary providers and modules. Then apply the configuration to create AWS resources.

```bash
terraform init
terraform apply
```

Confirm the action by entering `yes`. After the process completes, Terraform will create VPC, ECR repository, and EKS cluster. The necessary outputs for the next steps will be displayed.

### 2. Configure kubectl

Use the command from Terraform output to configure `kubectl` to connect to your new EKS cluster.

```bash
$(terraform output -raw kubectl_config_command)
```

You can verify the connection to the cluster by checking the nodes:

```bash
kubectl get nodes
```

### 3. Build and Push Docker Image to ECR

1. **Login to ECR:**
   Get the password to login to your ECR repository and login using Docker.

   ```bash
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(terraform output -raw ecr_repository_url)
   ```

2. **Build and push the image:**
   Use the build script to build and push your Django application image.

   ```bash
   ./build-and-push.sh $(terraform output -raw ecr_repository_url)
   ```

### 4. Deploy Application Using Helm

After the image is uploaded to ECR, you can deploy the Django application using the Helm chart.

```bash
helm install django-app ./charts/django-app \
  --set image.repository=$(terraform output -raw ecr_repository_url) \
  --set image.tag=latest
```

Verify the deployment:

```bash
kubectl get pods
kubectl get svc
kubectl get hpa
```

### 5. Get Application URL

Wait for the LoadBalancer to get an external IP address:

```bash
kubectl get svc -w
```

Once the EXTERNAL-IP appears, test your application:

```bash
curl http://<EXTERNAL-IP>/health/
```

## Security Features

- **Kubernetes Secrets**: Sensitive data (passwords, keys) stored securely in Kubernetes Secrets, not in ConfigMaps
- **ECR Policy**: Restricted to account owner only, removed wildcard access
- **S3 Backend**: Enabled with encryption and versioning for state management
- **HPA Configuration**: Auto-scaling 2-6 replicas based on CPU utilization (70%)

## Cleanup

To delete all created resources, run:

```bash
# Uninstall Helm release first
helm uninstall django-app

# Wait for LoadBalancer to be deleted
kubectl get svc

# Destroy infrastructure
terraform destroy
```

## Troubleshooting

**Problem:** kubectl can't connect to cluster  
**Solution:** Run `aws eks update-kubeconfig --region us-east-1 --name lesson-7-eks-cluster`

**Problem:** Pods in ImagePullBackOff  
**Solution:** Check ECR repository URL in values.yaml and ensure image was pushed

**Problem:** LoadBalancer pending  
**Solution:** Wait 2-3 minutes for AWS to provision the load balancer

## Author

Student: Denys  
Course: DevOps  
Lesson: 7 - Kubernetes on AWS EKS
