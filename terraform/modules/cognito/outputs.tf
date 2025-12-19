output "user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "ARN of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_endpoint" {
  description = "Endpoint of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.endpoint
}

output "user_pool_domain" {
  description = "Domain of the Cognito User Pool"
  value       = aws_cognito_user_pool_domain.main.domain
}

output "hr_portal_client_id" {
  description = "Client ID for HR Portal"
  value       = aws_cognito_user_pool_client.hr_portal.id
}

output "hr_portal_client_secret" {
  description = "Client Secret for HR Portal"
  value       = aws_cognito_user_pool_client.hr_portal.client_secret
  sensitive   = true
}

output "workspace_client_id" {
  description = "Client ID for Workspace"
  value       = aws_cognito_user_pool_client.workspace.id
}

output "workspace_client_secret" {
  description = "Client Secret for Workspace"
  value       = aws_cognito_user_pool_client.workspace.client_secret
  sensitive   = true
}

output "identity_pool_id" {
  description = "ID of the Cognito Identity Pool"
  value       = aws_cognito_identity_pool.main.id
}

output "authenticated_role_arn" {
  description = "ARN of the IAM role for authenticated users"
  value       = aws_iam_role.cognito_authenticated.arn
}

# Output for ALB Ingress annotations
output "alb_auth_cognito_annotation" {
  description = "ALB Ingress annotation for Cognito authentication"
  value = jsonencode({
    userPoolArn      = aws_cognito_user_pool.main.arn
    userPoolClientId = aws_cognito_user_pool_client.hr_portal.id
    userPoolDomain   = aws_cognito_user_pool_domain.main.domain
  })
}

# User Group ARNs
output "hr_admin_group_arn" {
  description = "ARN of HR Admin group"
  value       = "arn:aws:cognito-idp:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:userpool/${aws_cognito_user_pool.main.id}/group/hr-admin"
}

output "hr_staff_group_arn" {
  description = "ARN of HR Staff group"
  value       = "arn:aws:cognito-idp:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:userpool/${aws_cognito_user_pool.main.id}/group/hr-staff"
}

output "employees_group_arn" {
  description = "ARN of Employees group"
  value       = "arn:aws:cognito-idp:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:userpool/${aws_cognito_user_pool.main.id}/group/employees"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
