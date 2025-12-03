variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "innovatech.local"
}

variable "hr_portal_callback_urls" {
  description = "Callback URLs for HR Portal"
  type        = list(string)
  default     = ["https://hr-portal.internal.innovatech.local/callback"]
}

variable "hr_portal_logout_urls" {
  description = "Logout URLs for HR Portal"
  type        = list(string)
  default     = ["https://hr-portal.internal.innovatech.local/logout"]
}

variable "workspace_callback_urls" {
  description = "Callback URLs for Workspace access"
  type        = list(string)
  default     = ["https://workspace.internal.innovatech.local/callback"]
}

variable "workspace_logout_urls" {
  description = "Logout URLs for Workspace access"
  type        = list(string)
  default     = ["https://workspace.internal.innovatech.local/logout"]
}
