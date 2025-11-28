# 🚀 InnovaTech Employee Lifecycle Platform

> **Automated employee onboarding with cloud-native Linux workspaces**

[![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?style=flat-square&logo=amazon-aws)](https://aws.amazon.com/eks/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Workspaces-326CE5?style=flat-square&logo=kubernetes)](https://kubernetes.io/)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?style=flat-square&logo=terraform)](https://www.terraform.io/)

---

## 📋 Overview

A cloud-native HR platform that **automatically provisions Linux desktop workspaces** for new employees. When HR submits employee details, the system creates a containerized Ubuntu desktop accessible via web browser.

```mermaid
%%{init: {'theme': 'dark', 'themeVariables': { 'primaryColor': '#0ff', 'primaryTextColor': '#fff', 'primaryBorderColor': '#0ff', 'lineColor': '#f0f', 'secondaryColor': '#0f0', 'tertiaryColor': '#1a1a2e'}}}%%
flowchart LR
    subgraph INPUT[" "]
        HR["👤 HR User"]
    end
    
    subgraph CLOUD["☁️ AWS Cloud"]
        Portal["🌐 HR Portal"]
        API["⚡ Backend"]
        DB[("💾 DynamoDB")]
        K8S["☸️ EKS"]
        WS["🖥️ Workspace"]
    end
    
    subgraph OUTPUT[" "]
        EMP["👨‍💻 Employee"]
    end
    
    HR -->|1. Create| Portal
    Portal --> API
    API --> DB
    API -->|2. Provision| K8S
    K8S --> WS
    WS -->|3. Access| EMP
    
    style Portal fill:#0ff,stroke:#0ff,color:#000
    style API fill:#0f0,stroke:#0f0,color:#000
    style DB fill:#f0f,stroke:#f0f,color:#000
    style K8S fill:#ff0,stroke:#ff0,color:#000
    style WS fill:#f60,stroke:#f60,color:#000
```

---

## ⚡ Quick Start

### 🌐 HR Portal URL
```
http://ac0cd11d903e646dc890a3606c5999df-8a0c923d8bfa6cfe.elb.eu-west-1.amazonaws.com
```

### 📝 Create Employee Workspace
1. **Employees** → Add Employee (name, email, department, role)
2. **Provision Workspace** → Wait ~2 min
3. **Workspaces** → Open Desktop + copy password

---

## 🏗️ Architecture

📖 **Detailed docs**: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

```mermaid
%%{init: {'theme': 'dark', 'themeVariables': { 'primaryColor': '#0ff', 'lineColor': '#f0f'}}}%%
flowchart TB
    subgraph INTERNET["🌐 Internet"]
        USER["👤 Users"]
    end
    
    subgraph AWS["☁️ AWS eu-west-1"]
        subgraph VPC["VPC 10.0.0.0/16"]
            NLB["⚖️ Load Balancers"]
            
            subgraph EKS["☸️ EKS Cluster"]
                FE["React\nFrontend"]
                BE["Node.js\nBackend"]
                W1["🖥️ Workspace 1"]
                W2["🖥️ Workspace 2"]
                W3["🖥️ Workspace N"]
            end
        end
        
        DDB[("💾 DynamoDB")]
        ECR["📦 ECR"]
        AD["🔐 AD"]
    end
    
    USER --> NLB
    NLB --> FE & W1 & W2 & W3
    FE --> BE
    BE --> DDB
    BE --> EKS
    EKS -.-> ECR
    EKS -.-> AD
    
    style NLB fill:#0ff,stroke:#0ff,color:#000
    style FE fill:#0f0,stroke:#0f0,color:#000
    style BE fill:#0f0,stroke:#0f0,color:#000
    style DDB fill:#f0f,stroke:#f0f,color:#000
    style W1 fill:#f60,stroke:#f60,color:#000
    style W2 fill:#f60,stroke:#f60,color:#000
    style W3 fill:#f60,stroke:#f60,color:#000
```

---

## 🖥️ Workspace Features

| Tool | Description |
|------|-------------|
| 🐧 **Ubuntu 22.04** | Linux desktop via browser |
| 🖼️ **XFCE** | Lightweight desktop |
| 🌐 **Firefox** | Web browser |
| 💻 **Terminal** | xfce4-terminal |
| 🔒 **PuTTY** | SSH client |
| ☁️ **AWS CLI** | Cloud access (IRSA) |

---

## 🔐 Security Model

```mermaid
%%{init: {'theme': 'dark', 'themeVariables': { 'primaryColor': '#f0f', 'lineColor': '#0ff'}}}%%
flowchart LR
    subgraph DEPT["🏢 Department IRSA"]
        DEV["💻 developer-sa"]
        HR["👥 hr-sa"]
        MGR["📊 manager-sa"]
        ADM["🔑 admin-sa"]
    end
    
    subgraph AWS["☁️ AWS Permissions"]
        S3["📁 S3"]
        SSM["🔧 SSM"]
        DDB["💾 DynamoDB"]
    end
    
    DEV --> S3
    HR --> DDB
    MGR --> S3 & SSM
    ADM --> S3 & SSM & DDB
    
    style DEV fill:#0ff,stroke:#0ff,color:#000
    style HR fill:#0f0,stroke:#0f0,color:#000
    style MGR fill:#ff0,stroke:#ff0,color:#000
    style ADM fill:#f0f,stroke:#f0f,color:#000
```

| Feature | Status |
|---------|--------|
| **IRSA** | ✅ No static credentials |
| **Network Policies** | ✅ Namespace isolation |
| **Private Subnets** | ✅ Pods protected |
| **AD Integration** | ⚠️ Ready (innovatech.local) |

---

## 📁 Project Structure

```
📦 casestudy3
├── 📂 applications/
│   ├── 📂 hr-portal/          # React + Node.js
│   └── 📂 workspace/          # Ubuntu desktop container
├── 📂 kubernetes/             # K8s manifests
├── 📂 terraform/              # AWS infrastructure (IaC)
├── 📂 .github/workflows/      # CI/CD pipeline
└── 📂 docs/                   # Documentation
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| ☁️ **Cloud** | AWS (EKS, DynamoDB, ECR, VPC) |
| 🏗️ **IaC** | Terraform |
| 🐳 **Container** | Docker, Kubernetes |
| ⚡ **Backend** | Node.js, Express |
| 🎨 **Frontend** | React |
| 🖥️ **Desktop** | Ubuntu, XFCE, TigerVNC, noVNC |
| 🔄 **CI/CD** | GitHub Actions |

---

## 📊 AWS Resources

| Resource | Value |
|----------|-------|
| **EKS Cluster** | `innovatech-employee-lifecycle` |
| **Region** | `eu-west-1` (Ireland) |
| **VPC** | `10.0.0.0/16` |
| **Directory** | `innovatech.local` |

---

<p align="center">
  <sub>☁️ AWS • ☸️ Kubernetes • 🐳 Docker • 🎓 Fontys S3 2025</sub>
</p>
