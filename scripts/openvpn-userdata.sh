#!/bin/bash
set -e

# Log all output
exec > >(tee /var/log/openvpn-setup.log) 2>&1

echo "=== Starting OpenVPN Setup ==="

# Update system
yum update -y
amazon-linux-extras install epel -y
yum install -y openvpn easy-rsa iptables-services nginx httpd-tools

# Setup Easy-RSA
mkdir -p /etc/openvpn/easy-rsa
cp -r /usr/share/easy-rsa/3/* /etc/openvpn/easy-rsa/
cd /etc/openvpn/easy-rsa

# Initialize PKI
./easyrsa init-pki
./easyrsa --batch build-ca nopass
./easyrsa --batch build-server-full server nopass
./easyrsa gen-dh
openvpn --genkey secret /etc/openvpn/ta.key

# Copy certs
cp pki/ca.crt /etc/openvpn/
cp pki/issued/server.crt /etc/openvpn/
cp pki/private/server.key /etc/openvpn/
cp pki/dh.pem /etc/openvpn/

# Server config
cat > /etc/openvpn/server.conf <<EOF
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-auth ta.key 0

server 10.8.0.0 255.255.255.0
push "route 10.0.0.0 255.255.0.0"
push "dhcp-option DNS 10.0.0.2"
push "dhcp-option DOMAIN innovatech.local"

client-to-client
keepalive 10 120
cipher AES-256-GCM
auth SHA256
user nobody
group nobody
persist-key
persist-tun
status /var/log/openvpn/openvpn-status.log
log-append /var/log/openvpn/openvpn.log
verb 3
max-clients 100
EOF

mkdir -p /var/log/openvpn

# Enable IP forwarding
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
sysctl -p

# NAT rules
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
iptables -A FORWARD -i tun0 -j ACCEPT
iptables -A FORWARD -o tun0 -j ACCEPT
service iptables save
systemctl enable iptables

# Start OpenVPN
systemctl enable openvpn@server
systemctl start openvpn@server

# Generate client cert
cd /etc/openvpn/easy-rsa
./easyrsa --batch build-client-full hr-staff nopass

mkdir -p /etc/openvpn/clients
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

cat > /etc/openvpn/clients/innovatech-vpn.ovpn <<EOF
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

chmod 600 /etc/openvpn/clients/innovatech-vpn.ovpn

# Web server for config download
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

htpasswd -bc /etc/nginx/.htpasswd openvpn InnovatechVPN2024!
systemctl enable nginx
systemctl start nginx

echo "=== OpenVPN Setup Complete ==="
echo "VPN Server IP: $PUBLIC_IP"
echo "Download config from: https://$PUBLIC_IP (user: openvpn, pass: InnovatechVPN2024!)"
