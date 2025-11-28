#!/bin/bash
# Workspace Container Startup Script
# Supports both local and Active Directory authentication

set -e

echo "=========================================="
echo "Workspace Container Starting"
echo "=========================================="
echo "User: ${USER:-employee}"
echo "AD Domain: ${AD_DOMAIN:-not configured}"
echo "VNC Resolution: ${VNC_RESOLUTION:-1920x1080}"
echo "=========================================="

# Set defaults
USER="${USER:-employee}"
PASSWORD="${PASSWORD:-changeme}"
VNC_RESOLUTION="${VNC_RESOLUTION:-1920x1080}"
VNC_PORT="${VNC_PORT:-5901}"
NOVNC_PORT="${NOVNC_PORT:-6080}"

# Attempt AD join if credentials are provided
if [ -n "$AD_ADMIN_PASSWORD" ]; then
    echo "AD credentials detected, attempting domain join..."
    /join-ad.sh || echo "AD join failed, continuing with local auth"
else
    echo "No AD credentials, using local authentication"
fi

# Ensure home directory exists for local user
if [ ! -d "/home/${USER}" ]; then
    echo "Creating home directory for ${USER}..."
    mkdir -p "/home/${USER}"
    cp -r /etc/skel/. "/home/${USER}/" 2>/dev/null || true
fi

# Update local user password (for VNC access)
echo "${USER}:${PASSWORD}" | chpasswd 2>/dev/null || true

# Setup VNC directory
mkdir -p "/home/${USER}/.vnc"

# Create VNC startup script
cat > "/home/${USER}/.vnc/xstartup" << 'EOF'
#!/bin/bash
startxfce4 &
EOF
chmod +x "/home/${USER}/.vnc/xstartup"

# Set VNC password from environment
echo "${PASSWORD}" | vncpasswd -f > "/home/${USER}/.vnc/passwd"
chmod 600 "/home/${USER}/.vnc/passwd"

# Fix ownership
chown -R "${USER}:${USER}" "/home/${USER}" 2>/dev/null || true

# Create workspace directory
mkdir -p "/home/${USER}/workspace"
chown "${USER}:${USER}" "/home/${USER}/workspace"

# Start D-Bus (needed for XFCE)
mkdir -p /run/dbus
dbus-daemon --system --fork 2>/dev/null || true

# Start VNC server as the user
echo "Starting VNC server on display :1..."
su - "${USER}" -c "vncserver -kill :1 2>/dev/null; vncserver :1 -geometry ${VNC_RESOLUTION} -depth 24"

# Start noVNC (web-based VNC client)
echo "Starting noVNC on port ${NOVNC_PORT}..."
websockify --web=/usr/share/novnc/ "${NOVNC_PORT}" localhost:"${VNC_PORT}" &

echo "=========================================="
echo "Workspace Ready!"
echo "Access via: http://<host>:${NOVNC_PORT}/vnc.html"
echo "VNC Password: (set from PASSWORD env)"
echo "=========================================="

# Keep container running
tail -f /dev/null
