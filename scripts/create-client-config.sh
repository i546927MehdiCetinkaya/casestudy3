#!/bin/bash
mkdir -p /etc/openvpn/clients
PUBLIC_IP="54.195.44.238"

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
echo "Client config created at /etc/openvpn/clients/innovatech-vpn.ovpn"
