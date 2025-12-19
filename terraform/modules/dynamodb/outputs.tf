output "table_name" {
  description = "Name of the employees table"
  value       = aws_dynamodb_table.employees.name
}

output "table_arn" {
  description = "ARN of the employees table"
  value       = aws_dynamodb_table.employees.arn
}

output "workspaces_table_name" {
  description = "Name of the workspaces table"
  value       = aws_dynamodb_table.workspaces.name
}

output "workspaces_table_arn" {
  description = "ARN of the workspaces table"
  value       = aws_dynamodb_table.workspaces.arn
}
