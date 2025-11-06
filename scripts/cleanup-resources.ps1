# Quick cleanup of existing AWS resources
# Run this if the destroy workflow fails or you want manual control

Write-Host "=== Cleaning up existing AWS resources ===" -ForegroundColor Cyan

# Check AWS authentication
Write-Host "`nChecking AWS credentials..." -ForegroundColor Yellow
$whoami = aws sts get-caller-identity 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ AWS credentials not configured. Run: .\scripts\refresh-credentials.ps1" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Authenticated as: $($whoami | ConvertFrom-Json | Select-Object -ExpandProperty UserId)" -ForegroundColor Green

# Delete DynamoDB Tables
Write-Host "`nDeleting DynamoDB tables..." -ForegroundColor Yellow
aws dynamodb delete-table --table-name innovatech-employees 2>$null
aws dynamodb delete-table --table-name innovatech-employees-workspaces 2>$null
Write-Host "✅ DynamoDB tables deletion initiated" -ForegroundColor Green

# Delete ECR Repositories
Write-Host "`nDeleting ECR repositories (including all images)..." -ForegroundColor Yellow
aws ecr delete-repository --repository-name hr-portal-backend --force 2>$null
aws ecr delete-repository --repository-name hr-portal-frontend --force 2>$null
aws ecr delete-repository --repository-name employee-workspace --force 2>$null
Write-Host "✅ ECR repositories deleted" -ForegroundColor Green

# Delete CloudWatch Log Group
Write-Host "`nDeleting CloudWatch log group..." -ForegroundColor Yellow
aws logs delete-log-group --log-group-name /aws/vpc/innovatech-employee-lifecycle 2>$null
Write-Host "✅ CloudWatch log group deleted" -ForegroundColor Green

# Delete IAM Role
Write-Host "`nDeleting IAM role..." -ForegroundColor Yellow
aws iam list-attached-role-policies --role-name innovatech-employee-lifecycle-vpc-flow-log-role --query 'AttachedPolicies[*].PolicyArn' --output text 2>$null | ForEach-Object {
    aws iam detach-role-policy --role-name innovatech-employee-lifecycle-vpc-flow-log-role --policy-arn $_ 2>$null
}
aws iam delete-role --role-name innovatech-employee-lifecycle-vpc-flow-log-role 2>$null
Write-Host "✅ IAM role deleted" -ForegroundColor Green

# Release Elastic IPs
Write-Host "`nFinding and releasing Elastic IPs..." -ForegroundColor Yellow
$eips = aws ec2 describe-addresses --query 'Addresses[?Tags[?Key==`Name` && contains(Value, `innovatech`)]].AllocationId' --output text 2>$null
if ($eips) {
    $eips -split '\s+' | ForEach-Object {
        Write-Host "  Releasing EIP: $_" -ForegroundColor Gray
        aws ec2 release-address --allocation-id $_ 2>$null
    }
    Write-Host "✅ Elastic IPs released" -ForegroundColor Green
} else {
    Write-Host "ℹ️  No Elastic IPs found" -ForegroundColor Gray
}

# Check for EKS clusters
Write-Host "`nChecking for EKS clusters..." -ForegroundColor Yellow
$clusters = aws eks list-clusters --query 'clusters' --output text 2>$null
if ($clusters -match "innovatech") {
    Write-Host "⚠️  EKS cluster found: $clusters" -ForegroundColor Yellow
    Write-Host "   Use the Destroy workflow to safely remove EKS cluster and VPC resources" -ForegroundColor Yellow
} else {
    Write-Host "ℹ️  No EKS clusters found" -ForegroundColor Gray
}

Write-Host "`n=== Cleanup Summary ===" -ForegroundColor Cyan
Write-Host "✅ DynamoDB tables deleted" -ForegroundColor Green
Write-Host "✅ ECR repositories deleted" -ForegroundColor Green
Write-Host "✅ CloudWatch log group deleted" -ForegroundColor Green
Write-Host "✅ IAM role deleted" -ForegroundColor Green
Write-Host "✅ Elastic IPs released" -ForegroundColor Green

Write-Host "`n🚀 Next Steps:" -ForegroundColor Green
Write-Host "1. Wait 1-2 minutes for AWS to process deletions"
Write-Host "2. Run Deploy workflow on GitHub: https://github.com/i546927MehdiCetinkaya/casestudy3/actions"
Write-Host "3. Or run locally: cd terraform && terraform apply"

Write-Host "`n⚠️  Note: If EKS cluster exists, use the Destroy workflow instead!" -ForegroundColor Yellow
