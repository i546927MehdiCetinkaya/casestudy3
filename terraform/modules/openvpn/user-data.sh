#!/bin/bash
set -e

# Log all output
exec > >(tee /var/log/openvpn-setup.log) 2>&1

echo "=== Starting OpenVPN Setup ==="

# Update system
yum update -y
yum install -y amazon-linux-extras

# Install EPEL and OpenVPN
amazon-linux-extras install epel -y
yum install -y openvpn easy-rsa iptables-services

# Setup Easy-RSA for certificate generation
mkdir -p /etc/openvpn/easy-rsa
cp -r /usr/share/easy-rsa/3/* /etc/openvpn/easy-rsa/
cd /etc/openvpn/easy-rsa

# Initialize PKI
./easyrsa init-pki

# Build CA (non-interactive)
./easyrsa --batch build-ca nopass

# Generate server certificate
./easyrsa --batch build-server-full server nopass

# Generate DH parameters
./easyrsa gen-dh

# Generate TLS auth key
openvpn --genkey secret /etc/openvpn/ta.key

# Copy certificates to OpenVPN directory
cp pki/ca.crt /etc/openvpn/
cp pki/issued/server.crt /etc/openvpn/
cp pki/private/server.key /etc/openvpn/
cp pki/dh.pem /etc/openvpn/

# Create server configuration
cat > /etc/openvpn/server.conf <<EOF
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-auth ta.key 0

# VPN subnet for clients
server ${vpn_client_cidr}

# Push routes for VPC
push "route ${vpc_cidr}"

# Push DNS settings
push "dhcp-option DNS ${dns_server}"
push "dhcp-option DOMAIN ${domain_name}"

# Allow clients to reach each other
client-to-client

# Keep connection alive
keepalive 10 120

# Security settings
cipher AES-256-GCM
auth SHA256
tls-version-min 1.2

# Run as non-root
user nobody
group nobody
persist-key
persist-tun

# Logging
status /var/log/openvpn/openvpn-status.log
log-append /var/log/openvpn/openvpn.log
verb 3

# Max clients
max-clients 100
EOF

# Create log directory
mkdir -p /var/log/openvpn

# Enable IP forwarding
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
sysctl -p

# Configure iptables for NAT
iptables -t nat -A POSTROUTING -s ${vpn_client_cidr} -o eth0 -j MASQUERADE
iptables -A FORWARD -i tun0 -j ACCEPT
iptables -A FORWARD -o tun0 -j ACCEPT

# Save iptables rules
service iptables save
systemctl enable iptables

# Start OpenVPN
systemctl enable openvpn@server
systemctl start openvpn@server

# Generate client certificate
cd /etc/openvpn/easy-rsa
./easyrsa --batch build-client-full hr-staff nopass

# Create client config directory
mkdir -p /etc/openvpn/clients

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Create client config template
cat > /etc/openvpn/clients/hr-staff.ovpn <<EOF
client
dev tun
proto udp
remote $PUBLIC_IP 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
auth SHA256
key-direction 1
verb 3

<ca>
$(cat /etc/openvpn/ca.crt)
</ca>

<cert>
$(cat /etc/openvpn/easy-rsa/pki/issued/hr-staff.crt)
</cert>

<key>
$(cat /etc/openvpn/easy-rsa/pki/private/hr-staff.key)
</key>

<tls-auth>
$(cat /etc/openvpn/ta.key)
</tls-auth>
EOF

chmod 600 /etc/openvpn/clients/hr-staff.ovpn

# Store client config in SSM
aws ssm put-parameter \
  --name "/${project_name}/vpn/client-config" \
  --type "SecureString" \
  --value "$(cat /etc/openvpn/clients/hr-staff.ovpn)" \
  --overwrite \
  --region $(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Install simple web server to download configs (optional)
yum install -y nginx
cat > /etc/nginx/conf.d/vpn.conf <<EOF
server {
    listen 443 ssl;
    server_name _;
    
    ssl_certificate /etc/openvpn/server.crt;
    ssl_certificate_key /etc/openvpn/server.key;
    
    auth_basic "VPN Config Download";
    auth_basic_user_file /etc/nginx/.htpasswd;
    
    location / {
        alias /etc/openvpn/clients/;
        autoindex on;
    }
}
EOF

# Create basic auth for nginx
yum install -y httpd-tools
htpasswd -bc /etc/nginx/.htpasswd openvpn "${admin_password}"

systemctl enable nginx
systemctl start nginx

echo "=== OpenVPN Setup Complete ==="
echo "VPN Server IP: $PUBLIC_IP"
echo "Client config stored in SSM: /${project_name}/vpn/client-config"
