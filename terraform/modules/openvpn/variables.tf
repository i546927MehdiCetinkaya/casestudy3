variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for OpenVPN server"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for OpenVPN server"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "vpn_client_cidr" {
  description = "CIDR block for VPN clients"
  type        = string
  default     = "10.8.0.0/24"
}

variable "domain_name" {
  description = "Private domain name for Route 53"
  type        = string
  default     = "innovatech.local"
}

variable "public_hosted_zone_id" {
  description = "Public Route 53 hosted zone ID (optional)"
  type        = string
  default     = ""
}

variable "hr_portal_ip" {
  description = "IP address for HR Portal"
  type        = string
}

variable "api_ip" {
  description = "IP address for API"
  type        = string
}

variable "admin_password" {
  description = "Admin password for OpenVPN web interface"
  type        = string
  sensitive   = true
}
