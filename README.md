# Employee Lifecycle Automation & Virtual Workspaces on AWS EKS

## 🎯 Project Overview

**Innovatech Solutions** - End-to-End Employee Lifecycle Automation with Virtual Workspaces on AWS EKS using Zero Trust Architecture.

This project delivers a fully automated employee lifecycle management solution that includes:
- Automated employee onboarding and offboarding
- Virtual workspace provisioning (VS Code in browser)
- Zero Trust security architecture
- Kubernetes-based infrastructure on AWS EKS
- Infrastructure as Code with Terraform
- DynamoDB for employee data storage
- Secure VPC endpoints for private AWS service connectivity

## 📋 Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Deployment Guide](#deployment-guide)
- [Usage](#usage)
- [Security](#security)
- [Cost Management](#cost-management)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## ✨ Features

### Functional Requirements
- ✅ **REQ-P3-01**: Automated employee onboarding and offboarding
- ✅ **REQ-P3-02**: Virtual workspaces as device alternative
- ✅ **REQ-P3-03**: DynamoDB for employee data storage
- ✅ **REQ-P3-10**: Full RBAC in cloud & Kubernetes
- ✅ **REQ-P3-11**: Zero Trust architecture with micro-segmentation

### Technical Features
- **HR Self-Service Portal**: Web-based interface for employee management
- **Workspace Automation**: Automatic provisioning of VS Code browser workspaces
- **Zero Trust Security**: Network policies, least privilege, encryption
- **Monitoring & Logging**: CloudWatch integration with detailed metrics
- **Cost Governance**: Tagged resources with cost tracking
- **High Availability**: Multi-AZ deployment with auto-scaling

## 🏗️ Architecture

![Architecture Diagram](docs/architecture-diagram.png)

See [ARCHITECTURE.md](docs/ARCHITECTURE.md) for detailed architecture documentation.

### Key Components
- **AWS EKS Cluster**: Kubernetes control plane and worker nodes
- **VPC Architecture**: Public and private subnets across 3 AZs
- **DynamoDB**: Employee and workspace metadata storage
- **VPC Endpoints**: Private connectivity to AWS services (DynamoDB, ECR, CloudWatch)
- **Application Load Balancer**: HTTPS ingress for HR portal and workspaces
- **ECR**: Container image registry
- **CloudWatch**: Centralized logging and monitoring

## 🔧 Prerequisites

### Required Tools
- **AWS CLI** (v2.x): [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- **Terraform** (v1.0+): [Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- **kubectl** (v1.28+): [Installation Guide](https://kubernetes.io/docs/tasks/tools/)
- **Docker**: For building container images
- **Node.js** (v18+): For running the HR portal locally

### AWS Requirements
- AWS Account with appropriate permissions
- AWS CLI configured with credentials
- Sufficient service quotas for:
  - EKS clusters
  - VPC resources
  - EC2 instances
  - DynamoDB tables

### Permissions Required
- EKS full access
- VPC management
- DynamoDB access
- ECR access
- IAM role creation
- CloudWatch logs

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/i546927MehdiCetinkaya/casestudy3.git
cd casestudy3
```

### 2. Configure AWS Credentials
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, and region (eu-west-1)
```

### 3. Deploy Infrastructure
```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

### 4. Configure kubectl
```bash
aws eks update-kubeconfig --region eu-west-1 --name innovatech-employee-lifecycle
```

### 5. Deploy Kubernetes Resources
```bash
cd ../kubernetes
kubectl apply -f hr-portal.yaml
kubectl apply -f rbac.yaml
kubectl apply -f network-policies.yaml
kubectl apply -f workspaces.yaml
```

### 6. Build and Push Container Images
```bash
# Get ECR login
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com

# Build and push HR Portal backend
cd applications/hr-portal/backend
docker build -t hr-portal-backend .
docker tag hr-portal-backend:latest ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com/hr-portal-backend:latest
docker push ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com/hr-portal-backend:latest

# Build and push workspace image
cd ../../workspace
docker build -t employee-workspace .
docker tag employee-workspace:latest ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com/employee-workspace:latest
docker push ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com/employee-workspace:latest
```

## 📖 Deployment Guide

### Step-by-Step Deployment

#### 1. Terraform Infrastructure (20-30 minutes)
```bash
cd terraform
terraform init
terraform apply
```

**What gets deployed:**
- VPC with public/private subnets
- EKS cluster with managed node group
- DynamoDB tables for employees and workspaces
- VPC endpoints for DynamoDB, ECR, CloudWatch
- IAM roles with IRSA
- Security groups
- CloudWatch log groups

#### 2. Kubernetes Resources (5-10 minutes)
```bash
# Deploy namespaces and RBAC
kubectl apply -f kubernetes/rbac.yaml

# Deploy network policies
kubectl apply -f kubernetes/network-policies.yaml

# Deploy HR Portal
kubectl apply -f kubernetes/hr-portal.yaml

# Verify deployments
kubectl get pods -n hr-portal
kubectl get pods -n workspaces
```

#### 3. Verify Installation
```bash
# Check EKS cluster
kubectl cluster-info

# Check nodes
kubectl get nodes

# Check all pods
kubectl get pods --all-namespaces

# Get ALB URL
kubectl get ingress -n hr-portal
```

## 💻 Usage

### HR Portal Access

1. **Access the HR Portal**
   ```
   https://hr.innovatech.example.com
   ```

2. **Login Credentials** (default)
   - Username: `admin`
   - Password: `admin123` (change in production!)

### Employee Onboarding

1. Navigate to **Employees** > **Add New**
2. Fill in employee details:
   - First Name
   - Last Name
   - Email
   - Role (developer/manager/admin)
   - Department
3. Click **Create Employee**
4. System automatically:
   - Creates DynamoDB record
   - Provisions VS Code workspace
   - Sets up RBAC permissions
   - Generates secure workspace URL

### Workspace Access

After onboarding, employees receive:
- Workspace URL: `https://[firstname-lastname].workspaces.innovatech.example.com`
- Temporary password (sent securely)
- Development environment with pre-installed tools

### Employee Offboarding

1. Navigate to **Employees**
2. Select employee
3. Click **Offboard**
4. System automatically:
   - Marks employee as terminated
   - Deprovisions workspace
   - Deletes Kubernetes resources
   - Removes access permissions

## 🔒 Security

### Zero Trust Implementation

**Network Segmentation:**
- Default deny-all network policies
- Micro-segmentation between namespaces
- Explicit allow rules for required communication

**Access Control:**
- RBAC at Kubernetes level
- IAM roles for service accounts (IRSA)
- Least privilege principle
- Multi-factor authentication (recommended)

**Data Protection:**
- Encryption at rest (EBS, DynamoDB)
- Encryption in transit (TLS/HTTPS)
- KMS-managed encryption keys
- Secrets management with Kubernetes secrets

**Monitoring & Auditing:**
- VPC Flow Logs
- EKS audit logs
- CloudWatch metrics and alarms
- DynamoDB point-in-time recovery

### Security Best Practices

1. **Rotate credentials regularly**
2. **Enable MFA for all users**
3. **Use AWS Secrets Manager for production secrets**
4. **Implement WAF rules on ALB**
5. **Regular security scans of container images**
6. **Keep Kubernetes and node groups updated**

## 💰 Cost Management

### Estimated Monthly Costs (EU-West-1)

| Resource | Quantity | Monthly Cost (USD) |
|----------|----------|-------------------|
| EKS Cluster | 1 | $73 |
| EC2 t3.medium nodes | 3 | $100 |
| NAT Gateway | 3 | $100 |
| Application Load Balancer | 1 | $23 |
| DynamoDB (on-demand) | 2 tables | $5-20 |
| VPC Endpoints | 6 | $45 |
| EBS Volumes (gp3) | ~50GB | $5 |
| ECR Storage | 10GB | $1 |
| CloudWatch Logs | 10GB | $5 |
| **Total** | | **~$357-372/month** |

### Cost Optimization Tips

1. **Use Spot Instances** for dev/test environments (-70% cost)
2. **Right-size node instances** based on actual usage
3. **Enable DynamoDB auto-scaling** for variable workloads
4. **Use S3 lifecycle policies** for ECR images
5. **Set CloudWatch log retention** to 30 days
6. **Delete unused workspaces** regularly
7. **Use Reserved Instances** for production (save 30-50%)

### Resource Tagging Strategy
All resources are tagged with:
- `Project`: InnovatechEmployeeLifecycle
- `Environment`: production/staging/dev
- `ManagedBy`: Terraform
- `CostCenter`: IT-Infrastructure
- `Owner`: DevOps-Team

## 🧪 Testing

### Test Plan

See [tests/TEST_PLAN.md](tests/TEST_PLAN.md) for comprehensive testing documentation.

### Quick Tests

#### 1. Infrastructure Tests
```bash
# Verify Terraform outputs
terraform output

# Check EKS cluster health
aws eks describe-cluster --name innovatech-employee-lifecycle --region eu-west-1

# Verify VPC endpoints
aws ec2 describe-vpc-endpoints --region eu-west-1
```

#### 2. Application Tests
```bash
# Test HR Portal API
curl -X GET https://hr.innovatech.example.com/api/health

# Test employee creation
curl -X POST https://hr.innovatech.example.com/api/employees \
  -H "Content-Type: application/json" \
  -d '{"firstName":"Test","lastName":"User","email":"test@innovatech.com","role":"developer","department":"Engineering"}'

# Check workspace status
kubectl get pods -n workspaces
```

#### 3. Security Tests
```bash
# Verify network policies
kubectl get networkpolicies -n hr-portal
kubectl get networkpolicies -n workspaces

# Check RBAC
kubectl get clusterrolebindings | grep hr-portal
kubectl get rolebindings -n workspaces

# Test pod security
kubectl auth can-i create pods --as=system:serviceaccount:hr-portal:hr-portal-backend
```

### Automated Testing

```bash
cd tests
./run-tests.sh
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Pods not starting
```bash
# Check pod status
kubectl describe pod <pod-name> -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace>

# Common causes:
# - Image pull errors (check ECR permissions)
# - Resource limits (check node capacity)
# - ConfigMap/Secret missing
```

#### 2. Cannot connect to EKS cluster
```bash
# Update kubeconfig
aws eks update-kubeconfig --region eu-west-1 --name innovatech-employee-lifecycle

# Verify AWS credentials
aws sts get-caller-identity

# Check EKS cluster status
aws eks describe-cluster --name innovatech-employee-lifecycle --region eu-west-1
```

#### 3. Workspace provisioning fails
```bash
# Check HR Portal backend logs
kubectl logs -n hr-portal -l app=hr-portal-backend

# Verify service account permissions
kubectl describe sa hr-portal-backend -n hr-portal

# Check DynamoDB access
aws dynamodb describe-table --table-name innovatech-employees
```

#### 4. Network connectivity issues
```bash
# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Check VPC endpoints
aws ec2 describe-vpc-endpoints --region eu-west-1 --filters Name=vpc-id,Values=<vpc-id>

# Verify security groups
kubectl get svc -n hr-portal
```

### Debug Commands

```bash
# Get all resources in a namespace
kubectl get all -n hr-portal

# Describe a failing pod
kubectl describe pod <pod-name> -n <namespace>

# Check events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Execute commands in a pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# Port forward for local access
kubectl port-forward svc/hr-portal-backend 3000:80 -n hr-portal
```

## 📚 Additional Documentation

- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - Detailed architecture and design decisions
- [DEPLOYMENT.md](docs/DEPLOYMENT.md) - Step-by-step deployment guide
- [OPERATIONS.md](docs/OPERATIONS.md) - Operational procedures and runbooks
- [TESTING.md](docs/TESTING.md) - Comprehensive test scenarios and results
- [COST_ANALYSIS.md](docs/COST_ANALYSIS.md) - Detailed cost breakdown and optimization
- [DEVIATIONS.md](docs/DEVIATIONS.md) - Documented deviations from original requirements

## 📝 Project Structure

```
casestudy3/
├── terraform/                 # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│       ├── vpc/
│       ├── eks/
│       ├── dynamodb/
│       ├── vpc-endpoints/
│       ├── iam/
│       ├── ecr/
│       ├── monitoring/
│       └── security-groups/
├── kubernetes/                # Kubernetes manifests
│   ├── hr-portal.yaml
│   ├── workspaces.yaml
│   ├── rbac.yaml
│   └── network-policies.yaml
├── applications/              # Application code
│   ├── hr-portal/
│   │   ├── backend/          # Node.js API
│   │   └── frontend/         # React UI
│   └── workspace/            # VS Code workspace image
├── ansible/                  # Optional configuration management
├── scripts/                  # Deployment and utility scripts
├── tests/                    # Test scenarios and scripts
└── docs/                     # Documentation
    ├── ARCHITECTURE.md
    ├── DEPLOYMENT.md
    ├── OPERATIONS.md
    └── images/
```

## 👥 Team & Support

**Project Owner**: Mehdi Cetinkaya  
**Course**: Case Study 3 - Fontys ICT  
**Academic Year**: 2024-2025

## 📄 License

This project is created for educational purposes as part of Case Study 3 at Fontys University of Applied Sciences.

## 🙏 Acknowledgments

- AWS Documentation
- Kubernetes Documentation
- Case Study 2 repository structure
- Fontys ICT instructors and peers

---

**Last Updated**: November 6, 2025  
**Version**: 1.0.0