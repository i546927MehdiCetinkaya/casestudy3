# Zero Trust Architecture Implementation

This project has been updated to implement a Zero Trust architecture for the Employee Lifecycle Automation system.

## Key Changes

### 1. Network Isolation
- **Private Subnets**: All workloads (HR Portal, Workspaces) run in private subnets with no direct internet access.
- **NAT Instance**: A cost-effective NAT Instance (Amazon Linux 2023) replaces the NAT Gateway. It provides controlled internet access for updates but is restricted by Security Groups.
- **VPC Endpoints**: Traffic to AWS services (S3, ECR, DynamoDB, SSM, Logs) stays entirely within the AWS network via Interface and Gateway Endpoints.

### 2. Identity & Access Management
- **AWS Cognito**: Centralized identity provider for all applications.
  - **User Pools**: Manages users (HR Staff, Employees).
  - **Identity Pools**: Exchanges tokens for AWS credentials.
  - **Groups**: `hr-admin`, `hr-staff`, `employees`.
- **Internal ALBs**: Application Load Balancers are now `internal` scheme, accessible only via VPN/DirectConnect. They enforce Cognito authentication *before* traffic reaches the pods.

### 3. Micro-segmentation (Kubernetes)
- **Network Policies**: A "Default Deny" policy is applied to all namespaces.
  - Traffic is explicitly allowed only between specific components (e.g., Frontend -> Backend).
  - Egress is restricted to VPC Endpoints and internal DNS.
- **Security Groups**: Pods and Nodes have strict Security Groups limiting communication to necessary ports only.

## Deployment Instructions

### Prerequisites
- AWS CLI configured
- Terraform installed
- `kubectl` installed

### Step 1: Deploy Infrastructure
```bash
cd terraform
terraform init
terraform apply -auto-approve
```

### Step 2: Update Kubernetes Manifests
A helper script has been created to inject Terraform outputs (Cognito IDs, ARNs, Security Group IDs) into the Kubernetes manifests.

```powershell
cd scripts
.\update-k8s-manifests.ps1
```

### Step 3: Deploy Applications
```bash
# Connect to EKS
aws eks update-kubeconfig --region eu-west-1 --name innovatech-employee-lifecycle

# Apply manifests
kubectl apply -f kubernetes/namespaces.yaml
kubectl apply -f kubernetes/network-policies.yaml
kubectl apply -f kubernetes/hr-portal.yaml
kubectl apply -f kubernetes/workspaces.yaml
```

### Step 4: DNS Configuration
Since the ALBs are internal, you must configure DNS to point to them.
1. Get the ALB DNS names: `kubectl get ingress -A`
2. Update the Route53 Private Hosted Zone (created by Terraform) with these DNS names.
   - `hr-portal.internal.innovatech.local` -> HR Portal ALB
   - `*.workspace.internal.innovatech.local` -> Workspace ALB

## Verification
- Verify Pods are running: `kubectl get pods -A`
- Verify Network Policies: Try to `curl google.com` from a pod (should fail).
- Verify Access: Connect via VPN (or bastion) and access `https://hr-portal.internal.innovatech.local`. You should be redirected to Cognito.
