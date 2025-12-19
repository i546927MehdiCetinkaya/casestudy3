# =============================================================================
# Core Configuration
# =============================================================================
cluster_name = "innovatech-employee-lifecycle"
environment  = "production"
aws_region   = "eu-west-1"

# =============================================================================
# Network Configuration
# =============================================================================
vpc_cidr = "10.0.0.0/16"

# =============================================================================
# Domain Configuration - Changed to innovatech.local for Route53 private zone
# =============================================================================
domain_name = "innovatech.local"

# =============================================================================
# OpenVPN Configuration (Professional DNS Solution)
# Will push VPC DNS (10.0.0.2) to clients for Route53 private zone resolution
# =============================================================================
enable_openvpn         = true
openvpn_key_name       = "bastion-key"
openvpn_instance_type  = "t3.small"
openvpn_admin_password = "CHANGE_ME_BEFORE_DEPLOY"

# =============================================================================
# AWS Directory Service Configuration
# =============================================================================
directory_admin_password = "CHANGE_ME_BEFORE_DEPLOY"

# =============================================================================
# EKS Configuration
# =============================================================================
node_instance_types = ["t3.medium"]
node_desired_size   = 3
node_min_size       = 3
node_max_size       = 6

# =============================================================================
# Feature Flags
# =============================================================================
enable_directory_service = true  # AWS Managed Microsoft AD for LDAP/RBAC authentication
