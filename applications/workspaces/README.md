# Kasm Workspaces for Innovatech Zero Trust

Browser-based desktop workspaces per department using Kasm technology.

## Overview

Each department has a customized workspace image:

| Department | Image | Tools | Resources |
|------------|-------|-------|-----------|
| **Infra** | `workspace-infra` | PuTTY, FileZilla, Wireshark, VS Code, AWS CLI, kubectl, Terraform | 2 CPU, 4GB RAM, 20GB storage |
| **Development** | `workspace-dev` | VS Code, Git, Node.js, Python, Java, Docker CLI | 3 CPU, 6GB RAM, 50GB storage |
| **HR** | `workspace-hr` | Firefox, LibreOffice, Thunderbird, PDF tools | 1.5 CPU, 3GB RAM, 10GB storage |

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         VPN Access Only                          │
│                    (OpenVPN: 54.195.44.238)                      │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     EKS Cluster (Private)                        │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    workspaces namespace                    │  │
│  │                                                            │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │  │
│  │  │ ws-emp001   │  │ ws-emp002   │  │ ws-emp003   │       │  │
│  │  │ (infra)     │  │ (dev)       │  │ (hr)        │       │  │
│  │  │ Port: 3xxxx │  │ Port: 3xxxx │  │ Port: 3xxxx │       │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘       │  │
│  │         │                │                │               │  │
│  │         └────────────────┼────────────────┘               │  │
│  │                          │                                │  │
│  │                    ┌─────┴─────┐                          │  │
│  │                    │   PVCs    │                          │  │
│  │                    │  (gp3)    │                          │  │
│  │                    └───────────┘                          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    hr-portal namespace                     │  │
│  │                                                            │  │
│  │  ┌─────────────────────────┐  ┌────────────────────────┐  │  │
│  │  │   Frontend              │  │  Backend               │  │  │
│  │  │   hrportal.innovatech   │  │  /api/workspaces       │  │  │
│  │  │   :30080                │  │  :30081                │  │  │
│  │  └─────────────────────────┘  └────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## ECR Repositories

```
920120424621.dkr.ecr.eu-west-1.amazonaws.com/workspace-infra
920120424621.dkr.ecr.eu-west-1.amazonaws.com/workspace-dev
920120424621.dkr.ecr.eu-west-1.amazonaws.com/workspace-hr
```

## Building Images

### Prerequisites
- Docker installed
- AWS CLI configured
- ECR login

### Login to ECR
```bash
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 920120424621.dkr.ecr.eu-west-1.amazonaws.com
```

### Build and Push Images

**Infrastructure Workspace:**
```bash
cd applications/workspaces/infra
docker build -t workspace-infra .
docker tag workspace-infra:latest 920120424621.dkr.ecr.eu-west-1.amazonaws.com/workspace-infra:latest
docker push 920120424621.dkr.ecr.eu-west-1.amazonaws.com/workspace-infra:latest
```

**Development Workspace:**
```bash
cd applications/workspaces/dev
docker build -t workspace-dev .
docker tag workspace-dev:latest 920120424621.dkr.ecr.eu-west-1.amazonaws.com/workspace-dev:latest
docker push 920120424621.dkr.ecr.eu-west-1.amazonaws.com/workspace-dev:latest
```

**HR Workspace:**
```bash
cd applications/workspaces/hr
docker build -t workspace-hr .
docker tag workspace-hr:latest 920120424621.dkr.ecr.eu-west-1.amazonaws.com/workspace-hr:latest
docker push 920120424621.dkr.ecr.eu-west-1.amazonaws.com/workspace-hr:latest
```

## Kubernetes Deployment

### Apply Namespace and Quotas
```bash
kubectl apply -f kubernetes/workspace-namespace.yaml
```

### Workspaces are provisioned automatically
When HR creates an employee via the portal:
1. Backend calls `provisionWorkspace(employee)`
2. Creates Secret, PVC, Pod, Service
3. Returns VNC URL to employee

## Accessing Workspaces

1. **Connect to VPN** (required for all access)
   ```
   OpenVPN Server: 54.195.44.238
   ```

2. **Open workspace URL in browser**
   ```
   https://workspace.innovatech.local:<NodePort>
   ```

3. **Login with VNC credentials**
   - Username: `kasm_user`
   - Password: (provided during provisioning)

## Department-Specific Features

### Infrastructure (Infra)
- **Blue theme**
- Network diagnostic tools (nmap, tcpdump, wireshark)
- Remote access tools (PuTTY, FileZilla, Remmina)
- Cloud/DevOps tools (AWS CLI, kubectl, Terraform, Ansible)

### Development (Dev)
- **Green theme**
- IDE (VS Code with extensions)
- Languages (Node.js 20, Python 3, Java 17)
- Build tools (npm, yarn, Maven, Gradle)
- Docker CLI, kubectl

### HR (Human Resources)
- **Purple theme**
- Browsers (Firefox, Chromium)
- Office suite (LibreOffice)
- PDF tools
- Email client (Thunderbird)
- HR document templates

## Zero Trust Security

1. **VPN Required** - No public access
2. **Per-User Workspaces** - Isolated pods
3. **AD Integration** - innovatech.local domain
4. **Audit Logging** - All provisioning logged
5. **Resource Limits** - Per-department quotas
6. **Network Policies** - Namespace isolation

## Customization

### Adding Wallpapers
Replace placeholder PNG files:
- `infra/infra-wallpaper.png` (blue theme)
- `dev/dev-wallpaper.png` (green theme)
- `hr/hr-wallpaper.png` (purple theme)

### Modifying Tools
Edit the respective Dockerfile to add/remove packages.

## Troubleshooting

### Check workspace pod status
```bash
kubectl get pods -n workspaces -l type=kasm-workspace
```

### View pod logs
```bash
kubectl logs -n workspaces ws-<employee-id>
```

### Restart workspace
```bash
kubectl delete pod -n workspaces ws-<employee-id>
# Pod will auto-restart due to restartPolicy: Always
```

### Check PVC status
```bash
kubectl get pvc -n workspaces
```

## API Endpoints (Backend)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/workspaces` | Provision workspace |
| DELETE | `/api/workspaces/:id` | Deprovision workspace |
| GET | `/api/workspaces/:id/status` | Get workspace status |
| GET | `/api/workspaces` | List all workspaces |
| POST | `/api/workspaces/:id/restart` | Restart workspace |
