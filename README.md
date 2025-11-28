# InnovaTech Employee Lifecycle Platform

Automated employee onboarding system that provisions cloud workspaces with Linux desktops accessible via browser.

📖 **Architecture Documentation**: See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

---

## What is this?

A cloud-native HR platform that automatically creates dedicated Linux desktop workspaces for new employees. When HR submits employee details, the system provisions a containerized Ubuntu desktop environment accessible via web browser.

---

## The Problem

Traditional onboarding requires manual server setup, VPN configuration, and software installation. This takes days and creates security risks through shared credentials and inconsistent environments.

---

## The Solution

This system:
- Captures employee data via web portal
- Stores records in DynamoDB
- Provisions Ubuntu desktop pods on Kubernetes
- Exposes desktop via noVNC (browser-based access)
- Displays credentials in HR Portal

---

## How It Works

```
HR Portal → Backend API → DynamoDB → Kubernetes → Ubuntu Desktop Pod → noVNC Access
```

1. **Create Employee**: HR fills in employee form (name, email, department, role)
2. **Store Data**: Employee record saved to DynamoDB
3. **Provision Workspace**: Backend creates Kubernetes pod with Linux desktop
4. **LoadBalancer**: AWS NLB exposes the workspace publicly
5. **Display Credentials**: URL and password shown in HR Portal

---

## Workspace Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Base OS** | Ubuntu 22.04 | Standard Linux distribution |
| **Desktop** | XFCE4 | Lightweight desktop environment |
| **VNC Server** | TigerVNC | Remote desktop protocol server |
| **Web Access** | noVNC | Browser-based VNC client |
| **Port** | 6080 (HTTP) | noVNC web interface |

**Why noVNC?** It's just a way to access the Ubuntu desktop via browser. The underlying system is standard Ubuntu with XFCE desktop. You could also use a VNC client directly.

### Pre-installed Software
- Firefox browser
- Python 3 + pip
- Node.js 18 + npm
- Git
-essentials (g Build cc, make)
- VS Code (code-server)
- htop, vim, curl, wget

---

## Current Implementation Status

### ✅ Working Features
| Feature | Status | Description |
|---------|--------|-------------|
| HR Portal | ✅ | Create/manage employees via web UI |
| Employee Database | ✅ | DynamoDB storage for employee records |
| Workspace Provisioning | ✅ | Automatic Ubuntu desktop pod creation |
| Browser Access | ✅ | noVNC web-based desktop access |
| LoadBalancer URLs | ✅ | Public URLs per workspace |
| Credentials Display | ✅ | Password shown in Workspaces tab |

### ⚠️ Partially Implemented (Code ready, needs deployment)
| Feature | Status | Description |
|---------|--------|-------------|
| AWS Directory Service | ⚠️ | AD deployed (`innovatech.local`) - CODE READY for integration |
| IAM Roles per Department | ⚠️ | 5 roles exist - CODE READY for IRSA |
| Email Notifications | ⚠️ | SES configured but emails not sent |

### 🔧 Code Ready (Needs Build & Deploy)
| Feature | Files Added | To Enable |
|---------|-------------|-----------|
| AD Authentication | `workspace/Dockerfile`, `join-ad.sh`, `startup.sh` | Rebuild image, store AD password in SSM |
| IRSA per Department | `kubernetes/workspace-serviceaccounts.yaml` | Apply manifest, redeploy backend |

### ❌ Not Implemented
| Feature | Status | Description |
|---------|--------|-------------|
| SAML Federation | ❌ | No SSO integration |
| Persistent Storage | ❌ | Using emptyDir (data lost on pod restart) |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Internet                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AWS Load Balancers (NLB)                      │
│  ┌─────────────────┐    ┌─────────────────────────────────────┐ │
│  │ HR Portal LB    │    │ Workspace LBs (one per employee)    │ │
│  │ Port 80         │    │ Port 80 → noVNC                     │ │
│  └────────┬────────┘    └─────────────────┬───────────────────┘ │
└───────────│───────────────────────────────│─────────────────────┘
            │                               │
            ▼                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                     EKS Cluster (Private Subnets)                │
│  ┌─────────────────────────┐  ┌─────────────────────────────┐   │
│  │  Namespace: hr-portal   │  │  Namespace: workspaces      │   │
│  │  ┌─────────┐ ┌────────┐ │  │  ┌──────────────────────┐   │   │
│  │  │Frontend │ │Backend │ │  │  │ jan-jansen (pod)     │   │   │
│  │  │ (React) │ │(Node.js│ │  │  │ Ubuntu + XFCE + VNC  │   │   │
│  │  └─────────┘ └────────┘ │  │  └──────────────────────┘   │   │
│  │                         │  │  ┌──────────────────────┐   │   │
│  │                         │  │  │ kees-van-der-spek    │   │   │
│  │                         │  │  │ Ubuntu + XFCE + VNC  │   │   │
│  └─────────────────────────┘  │  └──────────────────────┘   │   │
│                               │  ┌──────────────────────┐   │   │
│                               │  │ pieter-de-vries      │   │   │
│                               │  │ Ubuntu + XFCE + VNC  │   │   │
│                               │  └──────────────────────┘   │   │
│                               └─────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│                       AWS Services                               │
│  ┌──────────┐  ┌─────────────┐  ┌──────────────────────────┐    │
│  │ DynamoDB │  │ ECR         │  │ Directory Service        │    │
│  │ Tables   │  │ Images      │  │ (Managed AD - unused)    │    │
│  └──────────┘  └─────────────┘  └──────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

---

## Quick Start

### Access HR Portal
```
http://ac0cd11d903e646dc890a3606c5999df-8a0c923d8bfa6cfe.elb.eu-west-1.amazonaws.com
```

### Provision a Workspace
1. Go to **Employees** tab
2. Click **Add Employee** or select existing employee
3. Click **Provision Workspace**
4. Wait ~2 minutes for LoadBalancer
5. Go to **Workspaces** tab
6. Click **Open Desktop** and use displayed password

---

## Enabling AD + IAM Integration

### Step 1: Store AD Admin Password in SSM
```powershell
# Option A: Run the setup script
.\scripts\setup-ad-ssm.ps1

# Option B: Manual command
aws ssm put-parameter `
    --name "/innovatech-employee-lifecycle/directory/admin-password" `
    --value "YOUR_AD_ADMIN_PASSWORD" `
    --type "SecureString" `
    --region eu-west-1
```

### Step 2: Apply ServiceAccounts
```bash
kubectl apply -f kubernetes/workspace-serviceaccounts.yaml
```

### Step 3: Rebuild & Push Workspace Image
```bash
cd applications/workspace
docker build -t 920120424621.dkr.ecr.eu-west-1.amazonaws.com/employee-workspace:latest .
docker push 920120424621.dkr.ecr.eu-west-1.amazonaws.com/employee-workspace:latest
```

### Step 4: Rebuild & Push HR Portal Backend
```bash
cd applications/hr-portal/backend
docker build -t 920120424621.dkr.ecr.eu-west-1.amazonaws.com/hr-portal-backend:latest .
docker push 920120424621.dkr.ecr.eu-west-1.amazonaws.com/hr-portal-backend:latest
kubectl rollout restart deployment hr-portal-backend -n hr-portal
```

### Step 5: Provision New Workspace
- New workspaces will automatically:
  - Join the AD domain `innovatech.local`
  - Use department-specific ServiceAccount
  - Have AWS CLI configured with IAM role via IRSA

---

## Project Structure

```
casestudy3/
├── applications/
│   ├── hr-portal/
│   │   ├── backend/          # Node.js Express API
│   │   │   └── src/
│   │   │       ├── routes/   # API endpoints
│   │   │       └── services/ # DynamoDB, K8s, SSM
│   │   └── frontend/         # React SPA
│   └── workspace/
│       ├── Dockerfile        # Ubuntu + XFCE + noVNC + SSSD
│       ├── join-ad.sh        # AD domain join script
│       ├── startup.sh        # Container entrypoint
│       └── sssd.conf.template # SSSD config template
├── terraform/
│   ├── main.tf              # Root module
│   └── modules/             # VPC, EKS, DynamoDB, IAM, etc.
├── kubernetes/
│   ├── hr-portal.yaml       # HR Portal deployment
│   ├── rbac.yaml            # Kubernetes RBAC
│   ├── workspace-serviceaccounts.yaml  # IRSA per department
│   └── namespaces.yaml      # Namespace definitions
├── scripts/
│   └── setup-ad-ssm.ps1     # AD SSM configuration script
├── .github/
│   └── workflows/
│       └── deploy.yml       # CI/CD pipeline
└── docs/
    ├── ARCHITECTURE.md      # Detailed architecture
    └── RBAC.md              # RBAC documentation
```

---

## Technology Stack

| Layer | Technology |
|-------|------------|
| **Cloud** | AWS (EKS, DynamoDB, ECR, NLB, VPC) |
| **IaC** | Terraform |
| **Container** | Docker, Kubernetes |
| **CI/CD** | GitHub Actions |
| **Frontend** | React, nginx |
| **Backend** | Node.js, Express |
| **Desktop** | Ubuntu 22.04, XFCE4, TigerVNC, noVNC |

---

## Known Issues

1. **LoadBalancer Wait Time**: New workspaces take ~2 minutes for LoadBalancer URL
2. **Password Sync**: If password doesn't work, use sync endpoint
3. **No Persistence**: Workspace data is lost on pod restart (emptyDir)
4. **AD Not Integrated**: Workspaces don't use Active Directory authentication

---

## Future Improvements

1. ~~**AD Integration**: Configure workspaces to authenticate via AWS Directory Service~~ ✅ CODE READY
2. ~~**IAM Role Assumption**: Allow workspaces to use department-specific IAM roles~~ ✅ CODE READY
3. **Persistent Storage**: Fix EBS CSI driver for persistent workspace data
4. **SSO**: Implement SAML federation for single sign-on
5. **SSH Access**: Add SSH server to workspaces as alternative to VNC
6. **HTTPS**: Add TLS termination on LoadBalancers

---

## Academic Context

**Case Study 3** | Fontys University of Applied Sciences | Semester 3 | 2025

Demonstrates:
- Cloud-native architecture
- Infrastructure as Code (Terraform)
- Container orchestration (Kubernetes)
- CI/CD pipelines (GitHub Actions)
- AWS managed services

**Student**: Mehdi Cetinkaya (i546927)
