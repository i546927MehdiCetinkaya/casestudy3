# Cleanup all orphaned VPCs and related resources
# This script will:
# 1. Delete all NAT Gateways
# 2. Release all Elastic IPs
# 3. Delete all Internet Gateways
# 4. Delete all Route Tables (except main)
# 5. Delete all Subnets
# 6. Delete all VPCs

$ErrorActionPreference = "Continue"
$region = "eu-west-1"

Write-Host "Starting VPC cleanup in region: $region" -ForegroundColor Yellow

# Get all VPCs
Write-Host "`nFetching all VPCs..." -ForegroundColor Cyan
$vpcs = aws ec2 describe-vpcs --region $region --query 'Vpcs[?IsDefault==`false`].VpcId' --output text

if ([string]::IsNullOrWhiteSpace($vpcs)) {
    Write-Host "No non-default VPCs found" -ForegroundColor Green
    exit 0
}

$vpcList = $vpcs -split '\s+'
Write-Host "Found $($vpcList.Count) VPCs to clean up: $($vpcList -join ', ')" -ForegroundColor Yellow

foreach ($vpc in $vpcList) {
    Write-Host "`n=== Cleaning up VPC: $vpc ===" -ForegroundColor Magenta
    
    # 1. Delete NAT Gateways
    Write-Host "  Checking for NAT Gateways..." -ForegroundColor Cyan
    $natGateways = aws ec2 describe-nat-gateways --region $region `
        --filter "Name=vpc-id,Values=$vpc" "Name=state,Values=available,pending,deleting" `
        --query 'NatGateways[].NatGatewayId' --output text
    
    if (![string]::IsNullOrWhiteSpace($natGateways)) {
        $natList = $natGateways -split '\s+'
        Write-Host "  Found $($natList.Count) NAT Gateway(s)" -ForegroundColor Yellow
        foreach ($nat in $natList) {
            Write-Host "    Deleting NAT Gateway: $nat" -ForegroundColor Yellow
            aws ec2 delete-nat-gateway --region $region --nat-gateway-id $nat
        }
        Write-Host "  Waiting 60s for NAT Gateways to delete..." -ForegroundColor Yellow
        Start-Sleep -Seconds 60
    }
    
    # 2. Detach and delete Internet Gateways
    Write-Host "  Checking for Internet Gateways..." -ForegroundColor Cyan
    $igws = aws ec2 describe-internet-gateways --region $region `
        --filters "Name=attachment.vpc-id,Values=$vpc" `
        --query 'InternetGateways[].InternetGatewayId' --output text
    
    if (![string]::IsNullOrWhiteSpace($igws)) {
        $igwList = $igws -split '\s+'
        Write-Host "  Found $($igwList.Count) Internet Gateway(s)" -ForegroundColor Yellow
        foreach ($igw in $igwList) {
            Write-Host "    Detaching IGW: $igw from VPC: $vpc" -ForegroundColor Yellow
            aws ec2 detach-internet-gateway --region $region --internet-gateway-id $igw --vpc-id $vpc
            Write-Host "    Deleting IGW: $igw" -ForegroundColor Yellow
            aws ec2 delete-internet-gateway --region $region --internet-gateway-id $igw
        }
    }
    
    # 3. Delete route table associations and route tables
    Write-Host "  Checking for Route Tables..." -ForegroundColor Cyan
    $routeTables = aws ec2 describe-route-tables --region $region `
        --filters "Name=vpc-id,Values=$vpc" `
        --query 'RouteTables[?Associations[0].Main != `true`].RouteTableId' --output text
    
    if (![string]::IsNullOrWhiteSpace($routeTables)) {
        $rtList = $routeTables -split '\s+'
        Write-Host "  Found $($rtList.Count) non-main Route Table(s)" -ForegroundColor Yellow
        foreach ($rt in $rtList) {
            # Delete associations first
            $associations = aws ec2 describe-route-tables --region $region `
                --route-table-ids $rt `
                --query 'RouteTables[].Associations[?Main != `true`].RouteTableAssociationId' --output text
            
            if (![string]::IsNullOrWhiteSpace($associations)) {
                $assocList = $associations -split '\s+'
                foreach ($assoc in $assocList) {
                    Write-Host "    Disassociating route table association: $assoc" -ForegroundColor Yellow
                    aws ec2 disassociate-route-table --region $region --association-id $assoc
                }
            }
            
            Write-Host "    Deleting Route Table: $rt" -ForegroundColor Yellow
            aws ec2 delete-route-table --region $region --route-table-id $rt
        }
    }
    
    # 4. Delete Subnets
    Write-Host "  Checking for Subnets..." -ForegroundColor Cyan
    $subnets = aws ec2 describe-subnets --region $region `
        --filters "Name=vpc-id,Values=$vpc" `
        --query 'Subnets[].SubnetId' --output text
    
    if (![string]::IsNullOrWhiteSpace($subnets)) {
        $subnetList = $subnets -split '\s+'
        Write-Host "  Found $($subnetList.Count) Subnet(s)" -ForegroundColor Yellow
        foreach ($subnet in $subnetList) {
            Write-Host "    Deleting Subnet: $subnet" -ForegroundColor Yellow
            aws ec2 delete-subnet --region $region --subnet-id $subnet
        }
    }
    
    # 5. Delete VPC
    Write-Host "  Deleting VPC: $vpc" -ForegroundColor Red
    aws ec2 delete-vpc --region $region --vpc-id $vpc
    Write-Host "  VPC $vpc deleted successfully!" -ForegroundColor Green
}

# 6. Release all unassociated Elastic IPs
Write-Host "`n=== Checking for unassociated Elastic IPs ===" -ForegroundColor Magenta
$eips = aws ec2 describe-addresses --region $region `
    --query 'Addresses[?AssociationId==null].AllocationId' --output text

if (![string]::IsNullOrWhiteSpace($eips)) {
    $eipList = $eips -split '\s+'
    Write-Host "Found $($eipList.Count) unassociated Elastic IP(s)" -ForegroundColor Yellow
    foreach ($eip in $eipList) {
        Write-Host "  Releasing EIP: $eip" -ForegroundColor Yellow
        aws ec2 release-address --region $region --allocation-id $eip
    }
}

Write-Host "`n=== Cleanup Complete ===" -ForegroundColor Green
Write-Host "All VPCs and related resources have been cleaned up" -ForegroundColor Green
