variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "environment" {
  description = "Environment name"
  type        = string
}

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
