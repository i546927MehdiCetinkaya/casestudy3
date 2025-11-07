variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_oidc_issuer" {
  description = "OIDC issuer URL for EKS"
  type        = string
}

variable "eks_oidc_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
}
