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
                    │    GitHub    │
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
├── modules/
│   ├── s3-backend/          # S3 and DynamoDB for Terraform state
│   ├── vpc/                 # VPC with public/private subnets and NAT
│   ├── ecr/                 # ECR repository
│   ├── eks/                 # EKS cluster + EBS CSI Driver
│   ├── jenkins/             # Jenkins via Helm
│   └── argo_cd/             # Argo CD via Helm + Application chart
│
├── django/                  # Django application source
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

- **AWS CLI** configured with appropriate credentials
- **Terraform** >= 1.0
- **kubectl**
- **Helm** >= 3.0
- **Git**
- A separate **GitHub repository** for Helm charts (monitored by Argo CD)

## Setup Instructions

### Step 1: Create Helm Charts Repository

Create a new GitHub repository for Helm charts that Argo CD will monitor:

```bash
mkdir ../lesson-7-helm-charts && cd ../lesson-7-helm-charts
git init
git remote add origin https://github.com/YOUR_USERNAME/lesson-7-helm-charts.git
cp -r ../lesson-7/charts .
git add . && git commit -m "Initial Helm charts"
git push -u origin main
```

### Step 2: Update Variables

Edit `variables.tf` or create `terraform.tfvars`:

```hcl
django_app_repo_url    = "https://github.com/YOUR_USERNAME/lesson-7-helm-charts.git"
jenkins_admin_password = "YOUR_SECURE_PASSWORD"
```

### Step 3: Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

This will create:

- VPC with public/private subnets
- EKS cluster with 2 nodes
- ECR repository
- EBS CSI Driver for persistent volumes
- Jenkins with Kubernetes agent (Kaniko)
- Argo CD with GitOps sync
- S3 + DynamoDB backend for Terraform state

### Step 4: Configure kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name lesson-7-eks-cluster

kubectl get nodes
kubectl get pods -n jenkins
kubectl get pods -n argocd
```

### Step 5: Access Jenkins

```bash
# Port-forward for local access
kubectl port-forward -n jenkins svc/jenkins 8080:8080
# Open: http://localhost:8080

# Get admin password
kubectl get secret -n jenkins jenkins \
  -o jsonpath='{.data.jenkins-admin-password}' | base64 -d
```

Login with `admin` / password from the command above.

### Step 6: Configure Jenkins Credentials

Go to **Manage Jenkins → Credentials → System → Global credentials**:

| ID                   | Type                   | Value                                           |
| -------------------- | ---------------------- | ----------------------------------------------- |
| `ecr-repository-url` | Secret text            | Output of `terraform output ecr_repository_url` |
| `github-token`       | Username with password | GitHub username + PAT with `repo` scope         |

### Step 7: Create Jenkins Pipeline

1. Click **New Item** → Name: `django-app-pipeline` → Type: **Pipeline**
2. In **Pipeline** section:
   - Definition: `Pipeline script from SCM`
   - SCM: Git
   - Repository URL: `https://github.com/YOUR_USERNAME/lesson-7.git`
   - Branch: `*/lesson-8-9`
   - Script Path: `Jenkinsfile`
3. Save

### Step 8: Access Argo CD

```bash
# Port-forward for local access
kubectl port-forward -n argocd svc/argocd-server 8080:80
# Open: http://localhost:8080

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
```

Login with `admin` / password from the command above.

### Step 9: Run Pipeline

1. Open `django-app-pipeline` in Jenkins
2. Click **Build Now**
3. The pipeline will:
   - Checkout source code
   - Build Docker image with Kaniko (no Docker daemon required)
   - Push image to ECR
   - Update image tag in Helm charts repo
4. Argo CD will automatically detect the change and deploy the new version

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
9. HPA manages scaling (2–6 replicas)
```

## Key Components

### Jenkins

- **Kubernetes Agent**: Pods spawned dynamically per build
- **Kaniko**: Docker-less image building inside Kubernetes
- **IRSA**: AWS credentials via service account (no static keys)
- **Persistent Storage**: 10Gi EBS volume for Jenkins home

### Argo CD

- **GitOps**: Declarative sync from Git repository
- **Auto-Sync**: Enabled with self-heal
- **Prune**: Removes resources deleted from Git
- **Retry**: 5 attempts with exponential backoff

### Security

- Jenkins IRSA for ECR access (no static credentials)
- Kubernetes Secrets for sensitive data
- ECR policy restricted to account
- S3 backend with encryption enabled
- EKS nodes in private subnets

## Verification

```bash
# Jenkins
kubectl get pods -n jenkins

# Argo CD
kubectl get pods -n argocd
kubectl get application -n argocd

# Django application
kubectl get pods
kubectl get svc
kubectl get hpa
```

## Troubleshooting

**Jenkins cannot push to ECR** (`denied: User is not authorized`):

```bash
aws iam list-attached-role-policies --role-name lesson-7-eks-cluster-jenkins-role
```

**Argo CD not syncing** (Application shows `OutOfSync`):

```bash
kubectl logs -n argocd deployment/argocd-repo-server
```

**ImagePullBackOff**:

```bash
aws ecr describe-images --repository-name lesson-7-ecr --region us-east-1
```

**Kaniko build fails**:

```bash
kubectl logs -n jenkins <pod-name> -c kaniko
```

## Cleanup

```bash
helm uninstall jenkins -n jenkins
helm uninstall argocd-apps -n argocd
helm uninstall argocd -n argocd

terraform destroy -auto-approve
```

## Author

**Student**: Denys Zelenskyi  
**Course**: DevOps  
**Lesson**: 8-9 — CI/CD with Jenkins and Argo CD  
**Branch**: `lesson-8-9`
