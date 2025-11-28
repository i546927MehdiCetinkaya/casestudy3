#!/bin/bash
# Active Directory Domain Join Script for Kubernetes Pods
# This script joins the container to AWS Directory Service (AD)

set -e

echo "=========================================="
echo "Active Directory Join Script"
echo "=========================================="

# Required environment variables
AD_DOMAIN="${AD_DOMAIN:-innovatech.local}"
AD_REALM="${AD_REALM:-INNOVATECH.LOCAL}"
AD_ADMIN_USER="${AD_ADMIN_USER:-Admin}"
AD_ADMIN_PASSWORD="${AD_ADMIN_PASSWORD:-}"
AD_JOIN_OU="${AD_JOIN_OU:-}"
DNS_SERVERS="${DNS_SERVERS:-}"

# Validate required variables
if [ -z "$AD_ADMIN_PASSWORD" ]; then
    echo "WARNING: AD_ADMIN_PASSWORD not set, skipping AD join"
    echo "Container will use local authentication only"
    exit 0
fi

echo "Domain: $AD_DOMAIN"
echo "Realm: $AD_REALM"
echo "Admin User: $AD_ADMIN_USER"

# Configure DNS to use Directory Service DNS servers
if [ -n "$DNS_SERVERS" ]; then
    echo "Configuring DNS servers: $DNS_SERVERS"
    
    # Backup resolv.conf
    cp /etc/resolv.conf /etc/resolv.conf.backup
    
    # Write new resolv.conf
    echo "search $AD_DOMAIN" > /etc/resolv.conf
    for dns in $DNS_SERVERS; do
        echo "nameserver $dns" >> /etc/resolv.conf
    done
    
    echo "DNS configuration updated"
    cat /etc/resolv.conf
fi

# Configure Kerberos
echo "Configuring Kerberos..."
cat > /etc/krb5.conf << EOF
[libdefaults]
    default_realm = $AD_REALM
    dns_lookup_realm = true
    dns_lookup_kdc = true
    ticket_lifetime = 24h
    renew_lifetime = 7d
    forwardable = true
    rdns = false

[realms]
    $AD_REALM = {
        kdc = $AD_DOMAIN
        admin_server = $AD_DOMAIN
    }

[domain_realm]
    .$AD_DOMAIN = $AD_REALM
    $AD_DOMAIN = $AD_REALM
EOF

echo "Kerberos configuration:"
cat /etc/krb5.conf

# Configure SSSD from template
echo "Configuring SSSD..."
envsubst < /etc/sssd/sssd.conf.template > /etc/sssd/sssd.conf
chmod 600 /etc/sssd/sssd.conf

# Verify domain is reachable
echo "Testing domain connectivity..."
if ! realm discover "$AD_DOMAIN" 2>/dev/null; then
    echo "WARNING: Cannot discover domain $AD_DOMAIN"
    echo "Check DNS configuration and network connectivity"
    exit 1
fi

echo "Domain discovered successfully:"
realm discover "$AD_DOMAIN"

# Join the domain
echo "Joining domain $AD_DOMAIN..."
if [ -n "$AD_JOIN_OU" ]; then
    echo "$AD_ADMIN_PASSWORD" | realm join --user="$AD_ADMIN_USER" \
        --computer-ou="$AD_JOIN_OU" "$AD_DOMAIN" 2>&1
else
    echo "$AD_ADMIN_PASSWORD" | realm join --user="$AD_ADMIN_USER" "$AD_DOMAIN" 2>&1
fi

# Verify join was successful
if realm list | grep -q "$AD_DOMAIN"; then
    echo "✓ Successfully joined domain $AD_DOMAIN"
else
    echo "✗ Failed to join domain"
    exit 1
fi

# Configure PAM for mkhomedir (auto-create home directories)
echo "Configuring PAM for automatic home directory creation..."
pam-auth-update --enable mkhomedir 2>/dev/null || true

# Configure NSS
echo "Configuring NSS..."
if ! grep -q "sss" /etc/nsswitch.conf; then
    sed -i 's/^passwd:.*/passwd:         files sss/' /etc/nsswitch.conf
    sed -i 's/^group:.*/group:          files sss/' /etc/nsswitch.conf
    sed -i 's/^shadow:.*/shadow:         files sss/' /etc/nsswitch.conf
fi

# Start SSSD
echo "Starting SSSD service..."
sssd -D -c /etc/sssd/sssd.conf

# Wait for SSSD to be ready
sleep 3

# Test AD user lookup
echo "Testing AD user lookup..."
if id "${AD_ADMIN_USER}@${AD_DOMAIN}" 2>/dev/null; then
    echo "✓ AD user lookup successful"
else
    echo "WARNING: Could not lookup AD user (SSSD may still be initializing)"
fi

echo "=========================================="
echo "AD Join Complete"
echo "=========================================="
