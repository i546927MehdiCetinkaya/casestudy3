output "hr_portal_internal_alb_sg_id" {
  description = "ID of HR Portal Internal ALB security group"
  value       = aws_security_group.hr_portal_internal_alb.id
}

output "hr_portal_internal_alb_sg_name" {
  description = "Name of HR Portal Internal ALB security group"
  value       = aws_security_group.hr_portal_internal_alb.name
}

output "workspace_internal_alb_sg_id" {
  description = "ID of Workspace Internal ALB security group"
  value       = aws_security_group.workspace_internal_alb.id
}

output "workspace_internal_alb_sg_name" {
  description = "Name of Workspace Internal ALB security group"
  value       = aws_security_group.workspace_internal_alb.name
}

output "eks_nodes_zero_trust_sg_id" {
  description = "ID of EKS Nodes Zero Trust security group"
  value       = aws_security_group.eks_nodes_zero_trust.id
}
