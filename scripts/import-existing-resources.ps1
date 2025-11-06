# Import Existing AWS Resources into Terraform State
# This script imports resources that already exist in AWS

$ErrorActionPreference = "Continue"

Write-Host "=== Importing Existing Resources into Terraform State ===" -ForegroundColor Cyan

# Change to terraform directory
Set-Location -Path "terraform"

# Initialize Terraform
Write-Host "`nInitializing Terraform..." -ForegroundColor Yellow
terraform init

# Import DynamoDB Tables
Write-Host "`nImporting DynamoDB Tables..." -ForegroundColor Yellow
terraform import module.dynamodb.aws_dynamodb_table.employees innovatech-employees
terraform import module.dynamodb.aws_dynamodb_table.workspaces innovatech-employees-workspaces

# Import ECR Repositories
Write-Host "`nImporting ECR Repositories..." -ForegroundColor Yellow
terraform import 'module.ecr.aws_ecr_repository.repos["hr-portal-backend"]' hr-portal-backend
terraform import 'module.ecr.aws_ecr_repository.repos["hr-portal-frontend"]' hr-portal-frontend
terraform import 'module.ecr.aws_ecr_repository.repos["employee-workspace"]' employee-workspace

# Import CloudWatch Log Group
Write-Host "`nImporting CloudWatch Log Group..." -ForegroundColor Yellow
terraform import module.vpc.aws_cloudwatch_log_group.vpc_flow_log /aws/vpc/innovatech-employee-lifecycle

# Import IAM Role
Write-Host "`nImporting IAM Role..." -ForegroundColor Yellow
terraform import module.vpc.aws_iam_role.vpc_flow_log innovatech-employee-lifecycle-vpc-flow-log-role

Write-Host "`n=== Checking for EIP and other VPC resources ===" -ForegroundColor Cyan
Write-Host "Note: EIP and other resources may need manual inspection" -ForegroundColor Yellow

# List existing Elastic IPs
Write-Host "`nExisting Elastic IPs:" -ForegroundColor Yellow
aws ec2 describe-addresses --query 'Addresses[*].[AllocationId,PublicIp,Tags[?Key==`Name`].Value|[0]]' --output table

Write-Host "`nNext Steps:" -ForegroundColor Green
Write-Host "1. Review the import results above"
Write-Host "2. If all imports succeeded, run: terraform plan"
Write-Host "3. If plan looks good, commit and push to trigger deployment"
Write-Host "4. If there are more conflicts, you may need to:"
Write-Host "   - Import additional resources OR"
Write-Host "   - Run the destroy workflow first, then redeploy"

Set-Location -Path ".."
