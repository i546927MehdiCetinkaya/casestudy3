#!/bin/bash
# Build script for Kasm workspace images
# Run this on an EC2 instance with Docker installed

set -e

AWS_REGION="eu-west-1"
AWS_ACCOUNT_ID="920120424621"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "=========================================="
echo "Kasm Workspace Image Builder"
echo "=========================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo yum update -y
    sudo yum install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    echo "Docker installed. Please log out and back in, then run this script again."
    exit 1
fi

# Check if Docker is running
if ! sudo docker info &> /dev/null; then
    echo "Starting Docker..."
    sudo systemctl start docker
fi

# Login to ECR
echo "Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} | sudo docker login --username AWS --password-stdin ${ECR_REGISTRY}

# Create temp directory for Dockerfiles
WORKDIR="/tmp/workspace-images"
mkdir -p ${WORKDIR}
cd ${WORKDIR}

# ============================================
# HR Workspace Image (smallest, build first)
# ============================================
echo ""
echo "=========================================="
echo "Building HR Workspace Image..."
echo "=========================================="

mkdir -p hr
cat > hr/Dockerfile << 'DOCKERFILE'
FROM kasmweb/core-ubuntu-jammy:1.15.0

USER root

ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup
WORKDIR $HOME

# Common utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget vim nano unzip ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Browsers
RUN apt-get update && apt-get install -y --no-install-recommends \
    firefox chromium-browser \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# LibreOffice
RUN apt-get update && apt-get install -y --no-install-recommends \
    libreoffice-calc libreoffice-writer libreoffice-impress \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# PDF and utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    evince thunar file-roller gedit thunderbird \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /home/kasm-user/workspace /home/kasm-user/Desktop /home/kasm-user/Documents && \
    chown -R 1000:1000 /home/kasm-user

ENV DEPARTMENT="hr"
ENV AD_DOMAIN="innovatech.local"

USER 1000
DOCKERFILE

cd hr
sudo docker build -t workspace-hr:latest .
sudo docker tag workspace-hr:latest ${ECR_REGISTRY}/workspace-hr:latest
sudo docker push ${ECR_REGISTRY}/workspace-hr:latest
echo "✅ HR workspace image pushed to ECR"
cd ..

# ============================================
# Infrastructure Workspace Image
# ============================================
echo ""
echo "=========================================="
echo "Building Infrastructure Workspace Image..."
echo "=========================================="

mkdir -p infra
cat > infra/Dockerfile << 'DOCKERFILE'
FROM kasmweb/core-ubuntu-jammy:1.15.0

USER root

ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup
WORKDIR $HOME

# Common utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget git vim nano htop jq unzip ca-certificates gnupg \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Network tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    net-tools dnsutils iputils-ping traceroute nmap tcpdump \
    iftop openssh-client telnet netcat-openbsd mtr iperf3 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Remote access tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    putty putty-tools filezilla remmina remmina-plugin-rdp remmina-plugin-vnc \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# VS Code
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg && \
    install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list && \
    apt-get update && apt-get install -y code && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" && \
    unzip /tmp/awscliv2.zip -d /tmp && /tmp/aws/install && rm -rf /tmp/aws*

# kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl

# Terraform
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com jammy main" > /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && apt-get install -y terraform && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /home/kasm-user/workspace /home/kasm-user/Desktop && \
    chown -R 1000:1000 /home/kasm-user

ENV DEPARTMENT="infrastructure"
ENV AD_DOMAIN="innovatech.local"

USER 1000
DOCKERFILE

cd infra
sudo docker build -t workspace-infra:latest .
sudo docker tag workspace-infra:latest ${ECR_REGISTRY}/workspace-infra:latest
sudo docker push ${ECR_REGISTRY}/workspace-infra:latest
echo "✅ Infrastructure workspace image pushed to ECR"
cd ..

# ============================================
# Development Workspace Image (largest)
# ============================================
echo ""
echo "=========================================="
echo "Building Development Workspace Image..."
echo "=========================================="

mkdir -p dev
cat > dev/Dockerfile << 'DOCKERFILE'
FROM kasmweb/core-ubuntu-jammy:1.15.0

USER root

ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup
WORKDIR $HOME

# Common utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget git vim nano htop jq unzip build-essential ca-certificates gnupg \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# VS Code
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg && \
    install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list && \
    apt-get update && apt-get install -y code && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest yarn && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Python 3
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv python3-dev \
    && pip3 install --upgrade pip virtualenv pytest black \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Java 17
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jdk maven \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Git tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    git-lfs gitk meld \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl

# AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" && \
    unzip /tmp/awscliv2.zip -d /tmp && /tmp/aws/install && rm -rf /tmp/aws*

# Create directories
RUN mkdir -p /home/kasm-user/workspace /home/kasm-user/Desktop /home/kasm-user/projects && \
    chown -R 1000:1000 /home/kasm-user

ENV DEPARTMENT="development"
ENV AD_DOMAIN="innovatech.local"
ENV JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"

USER 1000
DOCKERFILE

cd dev
sudo docker build -t workspace-dev:latest .
sudo docker tag workspace-dev:latest ${ECR_REGISTRY}/workspace-dev:latest
sudo docker push ${ECR_REGISTRY}/workspace-dev:latest
echo "✅ Development workspace image pushed to ECR"
cd ..

# Cleanup
echo ""
echo "Cleaning up..."
sudo docker system prune -f

echo ""
echo "=========================================="
echo "✅ All images built and pushed to ECR!"
echo "=========================================="
echo ""
echo "Images available at:"
echo "  - ${ECR_REGISTRY}/workspace-hr:latest"
echo "  - ${ECR_REGISTRY}/workspace-infra:latest"
echo "  - ${ECR_REGISTRY}/workspace-dev:latest"
