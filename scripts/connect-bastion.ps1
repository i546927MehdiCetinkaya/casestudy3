# =============================================================================
# InnovaTech HR Portal - Bastion Connection Script
# =============================================================================
# This script creates an SSH tunnel through the bastion host to access
# the private HR Portal in the EKS cluster.
#
# Usage:
#   .\connect-bastion.ps1
#
# After running, open your browser to:
#   - http://localhost:8080 - HR Portal Frontend
#   - http://localhost:8081 - HR Portal API
# =============================================================================

$BastionIP = "3.255.73.71"
$KeyPath = "$env:USERPROFILE\.ssh\bastion-key.pem"

# EKS Node IP (private) and NodePort services
$NodeIP = "10.0.58.37"
$FrontendPort = 30080
$BackendPort = 30081

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  InnovaTech HR Portal - Bastion Tunnel" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Check if key exists
if (-not (Test-Path $KeyPath)) {
    Write-Host "ERROR: SSH key not found at $KeyPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "The bastion-key.pem was created when the bastion was launched." -ForegroundColor Yellow
    Write-Host "If you don't have it, you need to create a new key pair in AWS." -ForegroundColor Yellow
    exit 1
}

Write-Host "Starting SSH tunnel to bastion ($BastionIP)..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Local ports:" -ForegroundColor Green
Write-Host "  - http://localhost:8080 -> HR Portal Frontend" -ForegroundColor White
Write-Host "  - http://localhost:8081 -> HR Portal API" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to disconnect" -ForegroundColor Yellow
Write-Host ""

# Create SSH tunnel with port forwarding via NodePort
# Traffic: localhost -> bastion -> EKS Node -> NodePort -> Pod
ssh -i $KeyPath `
    -o StrictHostKeyChecking=no `
    -o UserKnownHostsFile=/dev/null `
    -L 8080:${NodeIP}:${FrontendPort} `
    -L 8081:${NodeIP}:${BackendPort} `
    -N `
    ec2-user@$BastionIP
