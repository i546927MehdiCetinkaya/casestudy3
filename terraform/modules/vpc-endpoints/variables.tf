variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of private subnets"
  type        = list(string)
}

variable "route_table_ids" {
  description = "IDs of route tables"
  type        = list(string)
}

variable "environment" {
  description = "Environment name"
  type        = string
}
