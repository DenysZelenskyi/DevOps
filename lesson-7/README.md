# CI/CD Infrastructure with Jenkins, Terraform, and Argo CD

This project implements a complete CI/CD pipeline using Jenkins + Helm + Terraform + Argo CD for automated deployment of a Django application to AWS EKS.

## Architecture Overview

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   GitHub    │────▶│   Jenkins    │────▶│     ECR     │
│  (Source)   │     │ (Build & Push)│     │   (Images)  │
└─────────────┘     └──────────────┘     └─────────────┘
                            │
                            ▼
                    ┌──────────────┐
                    │  GitHub      │
                    │ (Helm Charts)│
                    └──────────────┘
                            │
                            ▼
                    ┌──────────────┐     ┌─────────────┐
                    │   Argo CD    │────▶│     EKS     │
                    │   (GitOps)   │     │  (Cluster)  │
                    └──────────────┘     └─────────────┘
```

## Project Structure

```
lesson-7/
│
├── main.tf                  # Main file connecting all modules
├── backend.tf               # S3 + DynamoDB backend configuration
├── variables.tf             # Input variables
├── outputs.tf               # Resource outputs
├── Jenkinsfile              # CI/CD pipeline definition
│
├── modules/                 # Terraform modules
│   ├── s3-backend/          # S3 and DynamoDB for state
│   ├── vpc/                 # VPC with subnets and NAT
│   ├── ecr/                 # ECR repository
│   ├── eks/                 # EKS cluster
│   │   ├── eks.tf
│   │   ├── aws_ebs_csi_driver.tf  # ✅ NEW: Persistent volumes support
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── jenkins/             # ✅ NEW: Jenkins via Helm
│   │   ├── jenkins.tf       # Helm release
│   │   ├── variables.tf
│   │   ├── providers.tf
│   │   ├── values.yaml      # Jenkins configuration
│   │   └── outputs.tf
│   │
│   └── argo_cd/             # ✅ NEW: Argo CD via Helm
│       ├── argocd.tf        # Helm release
│       ├── variables.tf
│       ├── providers.tf
│       ├── values.yaml      # Argo CD configuration
│       ├── outputs.tf
│       └── charts/          # Helm chart for Applications
│           ├── Chart.yaml
│           ├── values.yaml
│           └── templates/
│               ├── application.yaml
│               └── repository.yaml
│
├── django/                  # Django application
│   ├── Dockerfile
│   ├── manage.py
│   ├── requirements.txt
│   └── goit/
│
└── charts/
    └── django-app/          # Helm chart for Django
        ├── templates/
        │   ├── deployment.yaml
        │   ├── service.yaml
        │   ├── configmap.yaml
        │   ├── secret.yaml
        │   └── hpa.yaml
        ├── Chart.yaml
        └── values.yaml
```

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0
3. **kubectl** for Kubernetes management
4. **Helm** >= 3.0
5. **Git** for version control
6. **Separate GitHub repository** for Helm charts (will be created)

## Setup Instructions

### Step 1: Create Separate Helm Charts Repository

Create a new GitHub repository for Helm charts that Argo CD will monitor:

```bash
# Create new repository on GitHub: lesson-7-helm-charts
mkdir ../lesson-7-helm-charts
cd ../lesson-7-helm-charts
git init
git remote add origin https://github.com/YOUR_USERNAME/lesson-7-helm-charts.git

# Copy Helm chart
cp -r ../lesson-7/charts .

# Initial commit
git add .
git commit -m "Initial Helm charts"
git push -u origin main
```

### Step 2: Update Terraform Variables

Edit [variables.tf](variables.tf) or create `terraform.tfvars`:

```hcl
django_app_repo_url = "https://github.com/YOUR_USERNAME/lesson-7-helm-charts.git"
jenkins_admin_password = "YOUR_SECURE_PASSWORD"
```

### Step 3: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy infrastructure (takes ~15 minutes)
terraform apply -auto-approve
```

This will create:
- ✅ VPC with public/private subnets
- ✅ EKS cluster with 2 nodes
- ✅ ECR repository
- ✅ EBS CSI Driver for persistent volumes
- ✅ Jenkins with LoadBalancer
- ✅ Argo CD with LoadBalancer
- ✅ S3 backend for state management

### Step 4: Configure kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name lesson-7-eks-cluster

# Verify connection
kubectl get nodes
kubectl get pods -n jenkins
kubectl get pods -n argocd
```

### Step 5: Access Jenkins

Jenkins использует NodePort для экономии на LoadBalancer:

```bash
# Port-forward для локального доступа (рекомендуется)
kubectl port-forward -n jenkins svc/jenkins 8080:8080

# Открыть в браузере: http://localhost:8080

# Альтернатива: прямой доступ через NodePort
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
JENKINS_PORT=$(kubectl get svc jenkins -n jenkins -o jsonpath='{.spec.ports[0].nodePort}')
echo "Jenkins: http://$NODE_IP:$JENKINS_PORT"

# Get admin password
kubectl get secret -n jenkins jenkins -o jsonpath='{.data.jenkins-admin-password}' | base64 -d
```

Open Jenkins in browser and login with:
- Username: `admin`
- Password: (from command above)

### Step 6: Configure Jenkins Credentials

In Jenkins UI, go to **Manage Jenkins → Credentials → System → Global credentials**:

1. **ECR Repository URL** (ID: `ecr-repository-url`)
   - Type: Secret text
   - Secret: Get from `terraform output ecr_repository_url`

2. **GitHub Token** (ID: `github-token`)
   - Type: Username with password
   - Username: Your GitHub username
   - Password: GitHub Personal Access Token (PAT) with `repo` scope

### Step 7: Create Jenkins Pipeline

In Jenkins UI:

1. Click **New Item**
2. Name: `django-app-pipeline`
3. Type: **Pipeline**
4. In **Pipeline** section:
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: `https://github.com/YOUR_USERNAME/lesson-7.git`
   - Branch: `*/lesson-8-9`
   - Script Path: `Jenkinsfile`
5. Save

### Step 8: Access Argo CD

Argo CD использует NodePort для экономии на LoadBalancer:

```bash
# Port-forward для локального доступа (рекомендуется)
kubectl port-forward -n argocd svc/argocd-server 8080:80

# Открыть в браузере: http://localhost:8080

# Альтернатива: прямой доступ через NodePort
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
ARGOCD_PORT=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
echo "Argo CD: http://$NODE_IP:$ARGOCD_PORT"

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

Open Argo CD in browser and login with:
- Username: `admin`
- Password: (from command above)

### Step 9: Run Pipeline

1. In Jenkins, open `django-app-pipeline`
2. Click **Build Now**
3. Watch the pipeline:
   - ✅ Checkout code
   - ✅ Build Docker image with Kaniko
   - ✅ Push to ECR
   - ✅ Update Helm chart tag in separate repo
   - ✅ Push changes to Git

4. In Argo CD, watch auto-sync:
   - Detects chart changes
   - Syncs to cluster
   - Deploys new version

## CI/CD Flow

```
1. Developer pushes code to GitHub
            ↓
2. Jenkins pipeline triggered
            ↓
3. Kaniko builds Docker image (no Docker daemon needed)
            ↓
4. Image pushed to ECR with build number tag
            ↓
5. Jenkins updates values.yaml in Helm charts repo
            ↓
6. Argo CD detects Git changes (30s polling)
            ↓
7. Argo CD syncs cluster state with Git
            ↓
8. New pods deployed with updated image
            ↓
9. HPA manages scaling (2-6 replicas)
```

## Key Components

### Jenkins Configuration
- **Kubernetes Agent**: Pods spawned dynamically
- **Kaniko**: Docker-less image building
- **IRSA**: AWS credentials via service account
- **Persistent Storage**: 10Gi EBS volume

### Argo CD Configuration
- **GitOps**: Declarative sync from Git
- **Auto-Sync**: Enabled with self-heal
- **Prune**: Removes deleted resources
- **Retry**: 5 attempts with exponential backoff

### Security Features
- ✅ Jenkins IRSA for ECR access (no static credentials)
- ✅ Kubernetes Secrets for sensitive data
- ✅ ECR policy restricted to account
- ✅ S3 backend encryption enabled
- ✅ Private subnets for EKS nodes

## Verification

```bash
# Check Jenkins pods
kubectl get pods -n jenkins

# Check Argo CD pods
kubectl get pods -n argocd

# Check Django application
kubectl get pods -n default
kubectl get svc -n default
kubectl get hpa -n default

# View Argo CD Application status
kubectl get application -n argocd

# View recent pipeline builds
kubectl logs -n jenkins deployment/jenkins -f
```

## Troubleshooting

### Jenkins Can't Push to ECR
**Problem**: `denied: User is not authorized`  
**Solution**: Verify IRSA role has ECR policy attached:
```bash
aws iam list-attached-role-policies --role-name lesson-7-eks-cluster-jenkins-role
```

### Argo CD Not Syncing
**Problem**: Application shows "OutOfSync"  
**Solution**: Check repository access:
```bash
kubectl logs -n argocd deployment/argocd-repo-server
```

### Image Pull Errors
**Problem**: `ImagePullBackOff`  
**Solution**: Verify ECR repository and tag:
```bash
aws ecr describe-images --repository-name lesson-7-ecr --region us-east-1
```

### Kaniko Build Fails
**Problem**: `error building image`  
**Solution**: Check Jenkins pod logs:
```bash
kubectl logs -n jenkins <pod-name> -c kaniko
```

## Cleanup

```bash
# Delete Helm releases first
helm uninstall jenkins -n jenkins
helm uninstall argocd -n argocd
helm uninstall argocd-apps -n argocd

# Wait for LoadBalancers to be 69 (оптимизировано)
- EKS Cluster: $73/month
- 2x t3.medium nodes: ~$58/month (увеличено для работы Jenkins+ArgoCD)
- NAT Gateway: ~$32/month (1 вместо 3)
- NodePort services: $0/month (вместо LoadBalancers -$45/month)
- EBS volumes: ~$5/month
- ECR storage: ~$1/month

**Примененные оптимизации**:
✅ Один NAT Gateway вместо 3 (-$66/мес)
✅ NodePort вместо LoadBalancer (-$45/мес)
✅ t3.medium только где необходимо (+$29/мес, но обязательно)

**Дополнительная экономия** (см. [COST_OPTIMIZATION.md](COST_OPTIMIZATION.md)):
- Spot Instances: скидка ~70% (~$41/мес экономии)
- Автоматическое выключение: скидка ~66% (~$112/мес экономии)
- t3a.medium (AMD): скидка ~10% (~$6/мес экономии)
- NAT Gateway: ~$32/month
- LoadBalancers: ~$45/month
- EBS volumes: ~$5/month
- ECR storage: ~$1/month

**To reduce costs**:
- Use single NAT Gateway
- Use ClusterIP + Ingress instead of LoadBalancers
- Schedule cluster shutdown during non-work hours

## Author

**Student**: Denys  
**Course**: DevOps  
**Lesson**: 8-9 - CI/CD with Jenkins and Argo CD  
**Branch**: lesson-8-9
