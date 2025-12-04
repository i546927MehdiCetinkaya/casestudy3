output "vpn_public_ip" {
  description = "OpenVPN Server Public IP"
  value       = aws_eip.openvpn.public_ip
}

output "vpn_instance_id" {
  description = "OpenVPN EC2 Instance ID"
  value       = aws_instance.openvpn.id
}

output "private_hosted_zone_id" {
  description = "Route 53 Private Hosted Zone ID"
  value       = aws_route53_zone.private.zone_id
}

output "hr_portal_fqdn" {
  description = "Fully qualified domain name for HR Portal"
  value       = aws_route53_record.hr_portal.fqdn
}

output "api_fqdn" {
  description = "Fully qualified domain name for API"
  value       = aws_route53_record.api.fqdn
}

output "vpn_security_group_id" {
  description = "Security group ID for OpenVPN"
  value       = aws_security_group.openvpn.id
}

output "vpn_connection_instructions" {
  description = "Instructions to connect to VPN"
  value       = <<-EOT
    OpenVPN Server Setup Complete!
    
    1. Download OpenVPN client config from: https://${aws_eip.openvpn.public_ip}:443/
       Username: openvpn
       Password: (check SSM Parameter Store or use admin_password)
    
    2. Import the .ovpn file into your OpenVPN client
    
    3. Connect to VPN
    
    4. Access HR Portal at: https://hrportal.innovatech.local
       Access API at: https://api.innovatech.local
  EOT
}
