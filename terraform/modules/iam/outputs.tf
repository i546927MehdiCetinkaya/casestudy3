output "hr_portal_role_arn" {
  description = "ARN of HR Portal IAM role"
  value       = aws_iam_role.hr_portal.arn
}

output "workspace_role_arn" {
  description = "ARN of Workspace IAM role"
  value       = aws_iam_role.workspace.arn
}
