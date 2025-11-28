# Architecture

## Current System State

This document describes the **actual implemented state** of the InnovaTech Employee Lifecycle Platform as of November 2025.

---

## High-Level Architecture

```
┌────────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                       │
└────────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    ▼                               ▼
        ┌───────────────────┐           ┌───────────────────┐
        │  HR Portal NLB    │           │ Workspace NLBs    │
        │  (Network LB)     │           │ (per employee)    │
        │  Port 80          │           │ Port 80 → 6080    │
        └─────────┬─────────┘           └─────────┬─────────┘
                  │                               │
                  ▼                               ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                        AWS EKS CLUSTER                                      │
│                    (innovatech-employee-lifecycle)                          │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                     Private Subnets (10.0.101.0/24, 10.0.102.0/24)   │  │
│  │                                                                       │  │
│  │  ┌─────────────────────────┐      ┌─────────────────────────────┐    │  │
│  │  │  Namespace: hr-portal   │      │  Namespace: workspaces      │    │  │
│  │  │  ┌───────────────────┐  │      │                             │    │  │
│  │  │  │ hr-portal-frontend│  │      │  ┌───────────────────────┐  │    │  │
│  │  │  │ (React + nginx)   │  │      │  │ Pod: jan-jansen       │  │    │  │
│  │  │  │ Replicas: 2       │  │      │  │ ┌─────────────────┐   │  │    │  │
│  │  │  └───────────────────┘  │      │  │ │ Ubuntu 22.04    │   │  │    │  │
│  │  │                         │      │  │ │ XFCE Desktop    │   │  │    │  │
│  │  │  ┌───────────────────┐  │      │  │ │ TigerVNC        │   │  │    │  │
│  │  │  │ hr-portal-backend │  │      │  │ │ noVNC (:6080)   │   │  │    │  │
│  │  │  │ (Node.js/Express) │  │      │  │ └─────────────────┘   │  │    │  │
│  │  │  │ Replicas: 2       │  │      │  └───────────────────────┘  │    │  │
│  │  │  │                   │  │      │                             │    │  │
│  │  │  │ IRSA: hr-portal-  │  │      │  ┌───────────────────────┐  │    │  │
│  │  │  │       sa-role     │  │      │  │ Pod: kees-van-der-spek│  │    │  │
│  │  │  └───────────────────┘  │      │  │ (same as above)       │  │    │  │
│  │  └─────────────────────────┘      │  └───────────────────────┘  │    │  │
│  │                                    │                             │    │  │
│  │                                    │  ┌───────────────────────┐  │    │  │
│  │                                    │  │ Pod: pieter-de-vries  │  │    │  │
│  │                                    │  │ (same as above)       │  │    │  │
│  │                                    │  └───────────────────────┘  │    │  │
│  │                                    └─────────────────────────────┘    │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
        ┌───────────────┐  ┌───────────────┐  ┌───────────────┐
        │   DynamoDB    │  │     ECR       │  │  Directory    │
        │   ┌─────────┐ │  │  ┌─────────┐  │  │   Service     │
        │   │employees│ │  │  │backend  │  │  │ ┌───────────┐ │
        │   │table    │ │  │  │image    │  │  │ │innovatech │ │
        │   └─────────┘ │  │  └─────────┘  │  │ │.local     │ │
        │   ┌─────────┐ │  │  ┌─────────┐  │  │ │(UNUSED)   │ │
        │   │workspace│ │  │  │frontend │  │  │ └───────────┘ │
        │   │table    │ │  │  │image    │  │  └───────────────┘
        │   └─────────┘ │  │  └─────────┘  │
        └───────────────┘  │  ┌─────────┐  │
                           │  │workspace│  │
                           │  │image    │  │
                           │  └─────────┘  │
                           └───────────────┘
```

---

## Workspace Pod Architecture

Each employee workspace is a Kubernetes pod running:

```
┌─────────────────────────────────────────────────────────────┐
│                    Workspace Pod                             │
│  Name: {firstname}-{lastname} (e.g., jan-jansen)            │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                Container: linux-desktop                 │ │
│  │                                                         │ │
│  │  ┌─────────────────────────────────────────────────┐   │ │
│  │  │              Ubuntu 22.04 Base                   │   │ │
│  │  │  ┌─────────────────────────────────────────┐    │   │ │
│  │  │  │         XFCE4 Desktop Environment       │    │   │ │
│  │  │  │  ┌─────────────────────────────────┐    │    │   │ │
│  │  │  │  │         TigerVNC Server         │    │    │   │ │
│  │  │  │  │         (Display :1)            │    │    │   │ │
│  │  │  │  └───────────────┬─────────────────┘    │    │   │ │
│  │  │  │                  │                       │    │   │ │
│  │  │  │  ┌───────────────▼─────────────────┐    │    │   │ │
│  │  │  │  │       noVNC Web Server          │    │    │   │ │
│  │  │  │  │       Port 6080 (HTTP)          │    │    │   │ │
│  │  │  │  └─────────────────────────────────┘    │    │   │ │
│  │  │  └─────────────────────────────────────────┘    │   │ │
│  │  │                                                  │   │ │
│  │  │  Pre-installed: Firefox, Python3, Node.js,      │   │ │
│  │  │                 Git, build-essential, VS Code    │   │ │
│  │  └─────────────────────────────────────────────────┘   │ │
│  │                                                         │ │
│  │  Resources: 500m-1000m CPU, 1Gi-2Gi Memory             │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  Volumes:                                                    │
│  - /home/employee/workspace (emptyDir - NOT persistent)     │
│  - /tmp (emptyDir)                                          │
│                                                              │
│  Environment Variables:                                      │
│  - EMPLOYEE_ID: {uuid}                                      │
│  - EMPLOYEE_EMAIL: {email}                                  │
│  - EMPLOYEE_ROLE: {role}                                    │
│  - PASSWORD: (from Secret)                                  │
└─────────────────────────────────────────────────────────────┘
```

---

## Data Flow

### Employee Creation Flow
```
┌─────────┐     ┌─────────┐     ┌──────────┐
│ Browser │────▶│ Frontend│────▶│ Backend  │
│         │     │ (React) │     │ (Node.js)│
└─────────┘     └─────────┘     └────┬─────┘
                                     │
                    ┌────────────────┴────────────────┐
                    ▼                                 ▼
            ┌───────────────┐                ┌───────────────┐
            │   DynamoDB    │                │  Return JSON  │
            │ PutItem       │                │  {employeeId} │
            │ employees     │                └───────────────┘
            └───────────────┘
```

### Workspace Provisioning Flow
```
┌─────────┐     ┌─────────┐     ┌──────────┐     ┌─────────────┐
│ Browser │────▶│ Frontend│────▶│ Backend  │────▶│ Kubernetes  │
│ Click   │     │         │     │          │     │ API Server  │
│Provision│     └─────────┘     └────┬─────┘     └──────┬──────┘
└─────────┘                          │                  │
                                     │                  ▼
                                     │         ┌───────────────┐
                                     │         │ Create:       │
                                     │         │ - Secret      │
                                     │         │ - Pod         │
                                     │         │ - Service(NLB)│
                                     │         └───────┬───────┘
                                     │                 │
                                     │                 ▼
                                     │         ┌───────────────┐
                                     │         │ Wait for      │
                                     │         │ LoadBalancer  │
                                     │         │ (~2 minutes)  │
                                     │         └───────┬───────┘
                                     │                 │
                                     ▼                 ▼
                            ┌───────────────┐  ┌───────────────┐
                            │ DynamoDB      │  │ Return URL +  │
                            │ workspaces    │  │ Password      │
                            │ table         │  └───────────────┘
                            └───────────────┘
```

---

## Identity & Access Management

### What's Deployed (Infrastructure)

| Component | Status | Details |
|-----------|--------|---------|
| **AWS Directory Service** | ✅ Deployed | Managed AD: `innovatech.local` (d-936793cdc1) |
| **IAM Roles (Department)** | ✅ Deployed | 5 roles with department-specific permissions |
| **IRSA (HR Portal)** | ✅ Working | `hr-portal-sa-role` for backend pod |
| **Kubernetes RBAC** | ✅ Deployed | ClusterRoles and RoleBindings |

### IAM Roles Per Department

```
┌─────────────────────────────────────────────────────────────────────┐
│                    IAM ROLES (Deployed but NOT used by workspaces)  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
│  │ infra-role   │  │developer-role│  │ hr-role      │               │
│  │              │  │              │  │              │               │
│  │ - EKS:Desc   │  │ - ECR:*      │  │ - DynamoDB:  │               │
│  │ - EC2:Read   │  │ - CodeBuild  │  │   CRUD       │               │
│  │ - CloudWatch │  │ - CloudWatch │  │ - Workspaces │               │
│  │ - SSM:Read   │  │ - S3:Read    │  │   :Read      │               │
│  └──────────────┘  └──────────────┘  └──────────────┘               │
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐                                 │
│  │ manager-role │  │ admin-role   │                                 │
│  │              │  │              │                                 │
│  │ - DynamoDB:  │  │ - Full       │                                 │
│  │   ReadOnly   │  │   Access     │                                 │
│  │ - CloudWatch │  │              │                                 │
│  │   :Read      │  │              │                                 │
│  └──────────────┘  └──────────────┘                                 │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### What's NOT Working

```
┌─────────────────────────────────────────────────────────────────────┐
│                    MISSING INTEGRATIONS (NOW IMPLEMENTED IN CODE)    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ⏳ AD Authentication in Workspaces                                  │
│     - CODE READY: Dockerfile updated with sssd, realmd, adcli      │
│     - CODE READY: join-ad.sh script for domain join                │
│     - CODE READY: startup.sh with AD support                       │
│     - NEEDS: Rebuild image & store AD password in SSM              │
│                                                                      │
│  ⏳ IAM Role Assumption in Workspaces                                │
│     - CODE READY: workspace-serviceaccounts.yaml with IRSA         │
│     - CODE READY: workspace.js maps employee role → ServiceAccount │
│     - NEEDS: Apply K8s manifests & provision new workspace         │
│                                                                      │
│  ❌ SAML Federation                                                  │
│     - No Identity Provider configured                                │
│     - No SSO for AWS Console access                                 │
│                                                                      │
│  ❌ Kubernetes RBAC → AD Group Mapping                               │
│     - RBAC exists but not linked to AD groups                       │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Network Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        VPC: 10.0.0.0/16                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌───────────────────────┐    ┌───────────────────────┐             │
│  │  Public Subnet 1      │    │  Public Subnet 2      │             │
│  │  10.0.1.0/24          │    │  10.0.2.0/24          │             │
│  │  AZ: eu-west-1a       │    │  AZ: eu-west-1b       │             │
│  │                       │    │                       │             │
│  │  ┌─────────────────┐  │    │  ┌─────────────────┐  │             │
│  │  │ Internet GW     │  │    │  │ (Multi-AZ)      │  │             │
│  │  └─────────────────┘  │    │  └─────────────────┘  │             │
│  └───────────────────────┘    └───────────────────────┘             │
│                                                                      │
│  ┌───────────────────────┐    ┌───────────────────────┐             │
│  │  Private Subnet 1     │    │  Private Subnet 2     │             │
│  │  10.0.101.0/24        │    │  10.0.102.0/24        │             │
│  │  AZ: eu-west-1a       │    │  AZ: eu-west-1b       │             │
│  │                       │    │                       │             │
│  │  ┌─────────────────┐  │    │  ┌─────────────────┐  │             │
│  │  │ EKS Nodes       │  │    │  │ EKS Nodes       │  │             │
│  │  │ (t3.medium)     │  │    │  │ (t3.medium)     │  │             │
│  │  └─────────────────┘  │    │  └─────────────────┘  │             │
│  └───────────────────────┘    └───────────────────────┘             │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                    VPC Endpoints (PrivateLink)                │   │
│  │  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐      │   │
│  │  │ECR API │ │ECR DKR │ │   S3   │ │  SSM   │ │  CW    │      │   │
│  │  │        │ │        │ │Gateway │ │        │ │ Logs   │      │   │
│  │  └────────┘ └────────┘ └────────┘ └────────┘ └────────┘      │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ⚠️ NO NAT GATEWAY - All AWS access via VPC Endpoints              │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Terraform Modules

| Module | Purpose | Key Resources |
|--------|---------|---------------|
| `vpc` | Network foundation | VPC, subnets, IGW, route tables |
| `eks` | Kubernetes cluster | EKS cluster, node groups, OIDC |
| `dynamodb` | Data storage | employees table, workspaces table |
| `iam` | Access control | Department roles, IRSA roles |
| `vpc-endpoints` | Private AWS access | ECR, S3, SSM, CloudWatch endpoints |
| `systems-manager` | Configuration | SSM parameters |
| `ebs-csi` | Storage driver | EBS CSI driver (NOT working) |
| `security-groups` | Network security | EKS, node, pod security groups |
| `ecr` | Container registry | 3 repositories |
| `monitoring` | Observability | CloudWatch log groups |

---

## CI/CD Pipeline

```
┌─────────────────────────────────────────────────────────────────────┐
│                    GitHub Actions Workflow                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Trigger: workflow_dispatch (manual) or push to main                │
│                                                                      │
│  ┌─────────────────┐                                                │
│  │ 1. Validate     │  Terraform fmt, validate, kubeconform          │
│  └────────┬────────┘                                                │
│           ▼                                                          │
│  ┌─────────────────┐                                                │
│  │ 2. Terraform    │  terraform plan                                │
│  │    Plan         │                                                │
│  └────────┬────────┘                                                │
│           ▼                                                          │
│  ┌─────────────────┐                                                │
│  │ 3. Terraform    │  terraform apply                               │
│  │    Apply        │                                                │
│  └────────┬────────┘                                                │
│           ▼                                                          │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │ 4. Build & Push Images (parallel)                            │    │
│  │    ┌────────────┐  ┌────────────┐  ┌────────────┐           │    │
│  │    │ Backend    │  │ Frontend   │  │ Workspace  │           │    │
│  │    │ Image      │  │ Image      │  │ Image      │           │    │
│  │    └────────────┘  └────────────┘  └────────────┘           │    │
│  └─────────────────────────────────────────────────────────────┘    │
│           ▼                                                          │
│  ┌─────────────────┐                                                │
│  │ 5. Deploy K8s   │  kubectl apply -f kubernetes/                  │
│  │    Resources    │  Restart deployments                           │
│  └────────┬────────┘                                                │
│           ▼                                                          │
│  ┌─────────────────┐                                                │
│  │ 6. Post-Deploy  │  Health checks, API tests                      │
│  │    Tests        │                                                │
│  └─────────────────┘                                                │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Cost Breakdown

| Resource | Monthly Cost | Notes |
|----------|--------------|-------|
| EKS Control Plane | $72 | Fixed cost |
| EC2 Nodes (3x t3.medium) | ~$90 | On-demand pricing |
| NAT Gateway | **$0** | Eliminated via VPC endpoints |
| VPC Endpoints | ~$22 | 5 interface endpoints |
| DynamoDB | ~$5 | On-demand, low usage |
| Network Load Balancers | ~$50 | 1 per workspace + HR portal |
| Directory Service | ~$73 | Managed AD (unused!) |
| ECR | ~$2 | Image storage |
| **Total** | **~$314/month** | |

**Note**: Directory Service is the biggest waste - it costs $73/month but isn't integrated.

---

## What Would Complete Integration Look Like?

To fully implement AD + IAM roles:

### 1. AD Authentication in Workspaces (CODE READY ✅)

The workspace Dockerfile now includes SSSD/AD packages:
```dockerfile
# applications/workspace/Dockerfile
RUN apt-get install -y \
    sssd sssd-ad sssd-tools \
    realmd adcli krb5-user \
    samba-common-bin libnss-sss libpam-sss
```

The `join-ad.sh` script handles domain join at pod startup:
```bash
# Configures Kerberos, SSSD, and joins innovatech.local
realm join --user=Admin innovatech.local
```

**To enable:**
1. Store AD admin password in SSM: `aws ssm put-parameter --name "/innovatech-employee-lifecycle/directory/admin-password" --value "YOUR_PASSWORD" --type SecureString`
2. Rebuild and push workspace image: `docker build -t employee-workspace . && docker push`
3. Provision a new workspace - it will auto-join AD

### 2. IAM Role Assumption via IRSA (CODE READY ✅)

ServiceAccounts per department in `kubernetes/workspace-serviceaccounts.yaml`:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: workspace-developer
  namespace: workspaces
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::920120424621:role/innovatech-employee-lifecycle-developer-role"
```

The `workspace.js` service automatically assigns ServiceAccount based on employee role:
```javascript
const roleToServiceAccount = {
  'developer': 'workspace-developer',
  'hr': 'workspace-hr',
  'manager': 'workspace-manager',
  'admin': 'workspace-admin',
  'infra': 'workspace-infra'
};
```

**To enable:**
1. Apply ServiceAccounts: `kubectl apply -f kubernetes/workspace-serviceaccounts.yaml`
2. Rebuild HR Portal backend image
3. Provision new workspace - AWS CLI will automatically use department role

### 3. SAML Federation (NOT IMPLEMENTED)
- Configure AWS IAM Identity Provider
- Map AD groups to IAM roles
- Users assume roles via AD login

---

## Security Considerations

### Current Security Posture

| Aspect | Status | Risk |
|--------|--------|------|
| Network Isolation | ✅ Good | Pods in private subnets |
| VPC Endpoints | ✅ Good | No NAT, reduced attack surface |
| HTTPS/TLS | ❌ Missing | LoadBalancers on HTTP only |
| Authentication | ⚠️ Weak | Generated passwords, no MFA |
| Authorization | ⚠️ Weak | All workspaces same permissions |
| Secrets Management | ⚠️ Basic | K8s secrets, not AWS Secrets Manager |
| Audit Logging | ⚠️ Basic | CloudWatch logs only |

### Recommendations

1. Enable HTTPS on LoadBalancers with ACM certificates
2. Integrate AD for centralized authentication
3. Implement IRSA for workspace pods
4. Use AWS Secrets Manager for credentials
5. Enable AWS CloudTrail for audit logging

---

## Conclusion

The infrastructure is **partially complete**:
- ✅ Workspace provisioning works
- ✅ Browser-based desktop access works
- ✅ IAM roles and AD are deployed
- ⏳ AD and IAM role integration CODE READY (needs deployment)
- ❌ AD and IAM roles require image rebuild and K8s manifest apply

**New Files Added for AD/IRSA Integration:**
| File | Purpose |
|------|---------|
| `applications/workspace/Dockerfile` | Updated with SSSD/AD packages |
| `applications/workspace/join-ad.sh` | AD domain join script |
| `applications/workspace/startup.sh` | Container startup with AD support |
| `applications/workspace/sssd.conf.template` | SSSD configuration template |
| `kubernetes/workspace-serviceaccounts.yaml` | Department-based ServiceAccounts with IRSA |
| `scripts/setup-ad-ssm.ps1` | Script to store AD config in SSM |

The system demonstrates cloud-native architecture with **code ready** for enterprise identity integration.
