# 🚀 Node.js App Deployed on AWS EKS

A complete enterprise-grade DevOps project that deploys a Node.js application on AWS EKS using Terraform, Docker, GitHub Actions, and ArgoCD.

---

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [CI/CD Pipeline](#cicd-pipeline)
- [GitOps with ArgoCD](#gitops-with-argocd)
- [Cleanup](#cleanup)

---

## 🎯 Project Overview

This project demonstrates a complete DevOps pipeline where:

- A **Node.js** app is containerized with **Docker**
- Infrastructure is provisioned on **AWS** using **Terraform**
- **GitHub Actions** automatically builds and pushes Docker images to **ECR**
- **ArgoCD** watches the GitHub repo and deploys the app to **EKS** automatically

---

## 🏗️ Architecture

```
Developer pushes code to GitHub
        ↓
GitHub Actions CI Pipeline triggers
        ↓
Docker image built and pushed to AWS ECR
        ↓
Kubernetes manifest updated with new image tag
        ↓
ArgoCD detects change in GitHub repo
        ↓
ArgoCD deploys new version to EKS
        ↓
App is LIVE on internet via AWS Load Balancer ✅
```

---

## 🛠️ Tech Stack

| Tool | Purpose |
|---|---|
| **Node.js** | Application runtime |
| **Express.js** | Web framework |
| **Docker** | Containerization |
| **AWS EKS** | Kubernetes cluster |
| **AWS ECR** | Docker image registry |
| **AWS VPC** | Private network |
| **Terraform** | Infrastructure as Code |
| **GitHub Actions** | CI/CD automation |
| **ArgoCD** | GitOps deployment |
| **kubectl** | Kubernetes CLI |
| **Helm** | Kubernetes package manager |

---

## 📁 Project Structure

```
my-devops-project/
│
├── app/                        # Node.js application
│   ├── src/
│   │   └── index.js            # Main application code
│   ├── package.json            # Node.js dependencies
│   └── Dockerfile              # Docker build instructions
│
├── terraform/                  # AWS Infrastructure code
│   ├── main.tf                 # VPC + EKS cluster definition
│   ├── variables.tf            # Configurable variables
│   ├── outputs.tf              # Output values
│   └── backend.tf              # S3 remote state config
│
├── k8s/                        # Kubernetes manifests
│   ├── deployment.yaml         # App deployment config
│   ├── service.yaml            # LoadBalancer service
│   ├── ingress.yaml            # Ingress rules
│   └── argocd-app.yaml         # ArgoCD application config
│
├── .github/
│   └── workflows/              # GitHub Actions pipelines
│       ├── ci.yaml             # Build & push Docker image
│       └── cd.yaml             # Run Terraform
│
└── README.md
```

---

## ✅ Prerequisites

- AWS Account with IAM user (Admin access)
- GitHub Account
- WSL (Windows Subsystem for Linux) or Linux/Mac
- Following tools installed:
  - AWS CLI
  - Terraform
  - Docker
  - kubectl
  - Helm
  - Node.js 18+

---

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/asjadon/my-devops-project.git
cd my-devops-project
```

### 2. Configure AWS CLI

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Region: ap-south-1
# Output format: json
```

### 3. Create AWS Prerequisites

```bash
# Create S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket my-tf-state-ankit-2024 \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

# Create ECR repository
aws ecr create-repository \
  --repository-name my-devops-app \
  --region ap-south-1
```

### 4. Provision Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

### 5. Connect kubectl to EKS

```bash
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name my-devops-cluster
```

### 6. Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s
```

### 7. Access ArgoCD Dashboard

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0
```

Open browser at: `https://localhost:8080`

### 8. Set GitHub Secrets

Go to **GitHub → Settings → Secrets and variables → Actions** and add:

| Secret | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | Your AWS access key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key |
| `AWS_REGION` | `ap-south-1` |
| `AWS_ACCOUNT_ID` | Your 12-digit AWS account ID |

---

## ⚙️ CI/CD Pipeline

### CI Pipeline (ci.yaml)
Triggers when code is pushed to `main` branch and `app/**` files change:
1. Checkout code
2. Configure AWS credentials
3. Login to Amazon ECR
4. Build Docker image
5. Push image to ECR
6. Update Kubernetes manifest with new image tag
7. Commit updated manifest to GitHub

### CD Pipeline (cd.yaml)
Triggers when code is pushed to `main` branch and `terraform/**` files change:
1. Checkout code
2. Configure AWS credentials
3. Run `terraform init`
4. Run `terraform plan`
5. Run `terraform apply`

---

## 🔄 GitOps with ArgoCD

ArgoCD watches the `k8s/` folder in this repository and automatically deploys any changes to the EKS cluster.

```bash
# Apply ArgoCD application
kubectl apply -f k8s/argocd-app.yaml

# Check sync status
kubectl get application -n argocd

# Check deployed pods
kubectl get pods -n production

# Get app public URL
kubectl get service -n production
```

---

## 🌐 App Endpoints

| Endpoint | Description |
|---|---|
| `/` | Main response with version info |
| `/health` | Health check for Kubernetes probes |

---

## 🧹 Cleanup

To avoid AWS charges, destroy all resources when done:

```bash
cd terraform
terraform destroy -auto-approve
```

Then delete remaining resources:

```bash
# Delete ECR repository
aws ecr delete-repository \
  --repository-name my-devops-app \
  --region ap-south-1 \
  --force

# Delete S3 bucket
aws s3 rm s3://my-tf-state-ankit-2024 --recursive
aws s3api delete-bucket --bucket my-tf-state-ankit-2024 --region ap-south-1

# Delete DynamoDB table
aws dynamodb delete-table --table-name terraform-lock
```

---

## 👨‍💻 Author

**Ankit Singh Jadon** — [@asjadon](https://github.com/asjadon)

---



This project is open source and available under the [MIT License](LICENSE).
