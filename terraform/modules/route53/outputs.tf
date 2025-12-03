output "zone_id" {
  description = "ID of the Route53 zone"
  value       = aws_route53_zone.private.zone_id
}

output "zone_arn" {
  description = "ARN of the Route53 zone"
  value       = aws_route53_zone.private.arn
}

output "name_servers" {
  description = "Name servers of the Route53 zone"
  value       = aws_route53_zone.private.name_servers
}
