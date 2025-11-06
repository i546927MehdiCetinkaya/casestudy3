#!/usr/bin/env pwsh
# Deployment Script for Employee Lifecycle Automation System
# Windows PowerShell version

param(
    [Parameter(Mandatory=$false)]
    [string]$AwsRegion = "eu-west-1",
    
    [Parameter(Mandatory=$false)]
    [string]$ClusterName = "innovatech-employee-lifecycle",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipTerraform,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipKubernetes,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipImages
)

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Employee Lifecycle Automation Deployment" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

$prerequisites = @("aws", "terraform", "kubectl", "docker")
foreach ($cmd in $prerequisites) {
    if (!(Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: $cmd is not installed or not in PATH" -ForegroundColor Red
        exit 1
    }
    Write-Host "  ✓ $cmd found" -ForegroundColor Green
}

# Verify AWS credentials
Write-Host "`nVerifying AWS credentials..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity --output json | ConvertFrom-Json
    Write-Host "  ✓ Authenticated as: $($identity.Arn)" -ForegroundColor Green
} catch {
    Write-Host "ERROR: AWS credentials not configured" -ForegroundColor Red
    Write-Host "Run: aws configure" -ForegroundColor Yellow
    exit 1
}

$accountId = $identity.Account

# Step 1: Deploy Terraform Infrastructure
if (!$SkipTerraform) {
    Write-Host "`n======================================" -ForegroundColor Cyan
    Write-Host "Step 1: Deploying Terraform Infrastructure" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    
    Push-Location terraform
    
    Write-Host "`nInitializing Terraform..." -ForegroundColor Yellow
    terraform init
    
    Write-Host "`nPlanning Terraform deployment..." -ForegroundColor Yellow
    terraform plan -out=tfplan
    
    $confirm = Read-Host "`nProceed with Terraform apply? (yes/no)"
    if ($confirm -eq "yes") {
        Write-Host "`nApplying Terraform configuration..." -ForegroundColor Yellow
        terraform apply tfplan
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ Terraform deployment successful" -ForegroundColor Green
        } else {
            Write-Host "ERROR: Terraform deployment failed" -ForegroundColor Red
            Pop-Location
            exit 1
        }
    } else {
        Write-Host "Terraform deployment skipped" -ForegroundColor Yellow
        Pop-Location
        exit 0
    }
    
    Pop-Location
    
    Write-Host "`nWaiting for EKS cluster to be ready (this may take 15-20 minutes)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
}

# Step 2: Configure kubectl
Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "Step 2: Configuring kubectl" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

Write-Host "`nUpdating kubeconfig..." -ForegroundColor Yellow
aws eks update-kubeconfig --region $AwsRegion --name $ClusterName

Write-Host "`nVerifying cluster access..." -ForegroundColor Yellow
kubectl cluster-info

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ kubectl configured successfully" -ForegroundColor Green
} else {
    Write-Host "ERROR: kubectl configuration failed" -ForegroundColor Red
    exit 1
}

# Step 3: Deploy Kubernetes Resources
if (!$SkipKubernetes) {
    Write-Host "`n======================================" -ForegroundColor Cyan
    Write-Host "Step 3: Deploying Kubernetes Resources" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    
    Write-Host "`nDeploying RBAC configuration..." -ForegroundColor Yellow
    kubectl apply -f kubernetes/rbac.yaml
    
    Write-Host "`nDeploying Network Policies..." -ForegroundColor Yellow
    kubectl apply -f kubernetes/network-policies.yaml
    
    Write-Host "`nDeploying HR Portal..." -ForegroundColor Yellow
    kubectl apply -f kubernetes/hr-portal.yaml
    
    Write-Host "`nVerifying deployments..." -ForegroundColor Yellow
    kubectl get pods -n hr-portal
    
    Write-Host "  ✓ Kubernetes resources deployed" -ForegroundColor Green
}

# Step 4: Build and Push Container Images
if (!$SkipImages) {
    Write-Host "`n======================================" -ForegroundColor Cyan
    Write-Host "Step 4: Building and Pushing Container Images" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    
    $ecrRegistry = "$accountId.dkr.ecr.$AwsRegion.amazonaws.com"
    
    Write-Host "`nLogging in to ECR..." -ForegroundColor Yellow
    aws ecr get-login-password --region $AwsRegion | docker login --username AWS --password-stdin $ecrRegistry
    
    # Build HR Portal Backend
    Write-Host "`nBuilding HR Portal Backend..." -ForegroundColor Yellow
    Push-Location applications/hr-portal/backend
    docker build -t hr-portal-backend .
    docker tag hr-portal-backend:latest "$ecrRegistry/hr-portal-backend:latest"
    docker push "$ecrRegistry/hr-portal-backend:latest"
    Pop-Location
    Write-Host "  ✓ HR Portal Backend image pushed" -ForegroundColor Green
    
    # Build Workspace Image
    Write-Host "`nBuilding Employee Workspace..." -ForegroundColor Yellow
    Push-Location applications/workspace
    docker build -t employee-workspace .
    docker tag employee-workspace:latest "$ecrRegistry/employee-workspace:latest"
    docker push "$ecrRegistry/employee-workspace:latest"
    Pop-Location
    Write-Host "  ✓ Employee Workspace image pushed" -ForegroundColor Green
}

# Step 5: Deployment Summary
Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "Deployment Summary" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

Write-Host "`nCluster Information:"
kubectl get nodes
Write-Host "`nHR Portal Pods:"
kubectl get pods -n hr-portal
Write-Host "`nIngress:"
kubectl get ingress -n hr-portal

Write-Host "`n======================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

Write-Host "`nNext Steps:"
Write-Host "1. Wait for LoadBalancer to provision (~5 minutes)"
Write-Host "2. Get ALB URL: kubectl get ingress -n hr-portal"
Write-Host "3. Update DNS to point to ALB"
Write-Host "4. Access HR Portal at: https://hr.innovatech.example.com"
Write-Host "`nFor troubleshooting, see docs/TROUBLESHOOTING.md"
