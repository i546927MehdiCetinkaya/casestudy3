variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr_blocks" {
  description = "VPC CIDR blocks for internal access"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "corporate_cidr_blocks" {
  description = "Corporate network CIDR blocks (VPN/DirectConnect) that can access HR Portal"
  type        = list(string)
  default     = []
}
