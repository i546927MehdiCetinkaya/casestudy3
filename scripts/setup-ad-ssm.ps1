# Setup Active Directory Configuration in SSM Parameter Store
# Run this script once to configure AD integration

# Configuration
$Region = "eu-west-1"
$ClusterName = "innovatech-employee-lifecycle"

# Directory Service Details (from AWS console)
$DirectoryId = "d-936793cdc1"
$DirectoryDomain = "innovatech.local"
$DnsServers = "10.0.53.80 10.0.69.99"

# Note: You need to set this manually - get it from AWS console or terraform.tfvars
$AdminPassword = Read-Host -Prompt "Enter the Directory Service Admin password" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword)
$AdminPasswordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

Write-Host "Setting up SSM parameters for AD integration..." -ForegroundColor Cyan

# Store Directory ID
aws ssm put-parameter `
    --name "/$ClusterName/directory/id" `
    --value $DirectoryId `
    --type "String" `
    --description "AWS Directory Service ID" `
    --overwrite `
    --region $Region

# Store Domain
aws ssm put-parameter `
    --name "/$ClusterName/directory/domain" `
    --value $DirectoryDomain `
    --type "String" `
    --description "Directory Service domain name" `
    --overwrite `
    --region $Region

# Store DNS Servers
aws ssm put-parameter `
    --name "/$ClusterName/directory/dns-servers" `
    --value $DnsServers `
    --type "String" `
    --description "Directory Service DNS server IPs" `
    --overwrite `
    --region $Region

# Store Admin Password (encrypted)
aws ssm put-parameter `
    --name "/$ClusterName/directory/admin-password" `
    --value $AdminPasswordPlain `
    --type "SecureString" `
    --description "Directory Service admin password" `
    --overwrite `
    --region $Region

# Clear the password from memory
$AdminPasswordPlain = $null
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

Write-Host "SSM parameters created successfully!" -ForegroundColor Green

# Verify
Write-Host "`nVerifying SSM parameters..." -ForegroundColor Cyan
aws ssm get-parameters-by-path `
    --path "/$ClusterName/directory" `
    --region $Region `
    --query "Parameters[*].{Name:Name,Type:Type}" `
    --output table
