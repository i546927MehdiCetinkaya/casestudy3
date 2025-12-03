# Variables for Employee Lifecycle Automation Infrastructure

variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "innovatech-employee-lifecycle"
}

variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dynamodb_table_name" {
  description = "Name of DynamoDB table for employee data"
  type        = string
  default     = "innovatech-employees"
}

variable "enable_vpn" {
  description = "Enable VPN for administrative access"
  type        = bool
  default     = false
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed for administrative access"
  type        = list(string)
  default     = []
}

variable "domain_name" {
  description = "Internal domain name for the private hosted zone"
  type        = string
  default     = "internal.innovatech.local"
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.medium", "t3.large"]
}

variable "node_desired_size" {
  description = "Desired number of nodes in EKS node group"
  type        = number
  default     = 3
}

variable "node_min_size" {
  description = "Minimum number of nodes in EKS node group"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes in EKS node group"
  type        = number
  default     = 6
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

# Directory Service Configuration
variable "enable_directory_service" {
  description = "Enable AWS Directory Service for identity management"
  type        = bool
  default     = true
}

variable "directory_admin_password" {
  description = "Admin password for AWS Directory Service"
  type        = string
  sensitive   = true
  default     = ""
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

# =============================================================================
# ZERO TRUST CONFIGURATION
# =============================================================================

# HR Portal Access Control
variable "corporate_cidr_blocks" {
  description = "Corporate network CIDR blocks (VPN/DirectConnect) that can access HR Portal"
  type        = list(string)
  default     = []
}

# NAT Instance Configuration (instead of NAT Gateway)
variable "use_nat_instance" {
  description = "Use NAT Instance instead of NAT Gateway for better security control and cost efficiency"
  type        = bool
  default     = true
}

variable "nat_instance_type" {
  description = "Instance type for NAT Instance"
  type        = string
  default     = "t3.micro"
}

# =============================================================================
# COGNITO CONFIGURATION
# =============================================================================

variable "hr_portal_callback_urls" {
  description = "Callback URLs for HR Portal Cognito client"
  type        = list(string)
  default     = ["https://hr-portal.internal.innovatech.local/callback"]
}

variable "hr_portal_logout_urls" {
  description = "Logout URLs for HR Portal Cognito client"
  type        = list(string)
  default     = ["https://hr-portal.internal.innovatech.local/logout"]
}

variable "workspace_callback_urls" {
  description = "Callback URLs for Workspace Cognito client"
  type        = list(string)
  default     = ["https://workspace.internal.innovatech.local/callback"]
}

variable "workspace_logout_urls" {
  description = "Logout URLs for Workspace Cognito client"
  type        = list(string)
  default     = ["https://workspace.internal.innovatech.local/logout"]
}
