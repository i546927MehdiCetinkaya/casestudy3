variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the private hosted zone"
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
