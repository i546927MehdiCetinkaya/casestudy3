variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of private subnets for EKS nodes"
  type        = list(string)
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}
