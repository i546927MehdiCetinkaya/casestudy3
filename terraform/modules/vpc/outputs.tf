output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "private_route_table_ids" {
  description = "IDs of private route tables"
  value       = aws_route_table.private[*].id
}

output "nat_gateway_ids" {
  description = "IDs of NAT gateways (empty if using NAT Instance)"
  value       = aws_nat_gateway.main[*].id
}

output "nat_instance_id" {
  description = "ID of NAT Instance (null if using NAT Gateway)"
  value       = var.use_nat_instance ? aws_instance.nat[0].id : null
}

output "nat_instance_private_ip" {
  description = "Private IP of NAT Instance"
  value       = var.use_nat_instance ? aws_instance.nat[0].private_ip : null
}

output "nat_instance_security_group_id" {
  description = "Security group ID of NAT Instance"
  value       = aws_security_group.nat_instance.id
}
