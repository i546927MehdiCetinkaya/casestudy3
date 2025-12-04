#!/bin/bash
# Infrastructure Department Startup Script
set -e

DESKTOP_DIR="/home/kasm-user/Desktop"
mkdir -p "$DESKTOP_DIR"

# Create desktop shortcuts for infrastructure tools
cat > "$DESKTOP_DIR/Terminal.desktop" << 'EOF'
[Desktop Entry]
Name=Terminal
Comment=Terminal Emulator
Exec=xfce4-terminal
Icon=utilities-terminal
Type=Application
Categories=System;TerminalEmulator;
EOF

cat > "$DESKTOP_DIR/VS-Code.desktop" << 'EOF'
[Desktop Entry]
Name=Visual Studio Code
Comment=Code Editor
Exec=/usr/share/code/code --no-sandbox
Icon=vscode
Type=Application
Categories=Development;IDE;
EOF

cat > "$DESKTOP_DIR/PuTTY.desktop" << 'EOF'
[Desktop Entry]
Name=PuTTY SSH Client
Comment=SSH and Telnet Client
Exec=putty
Icon=putty
Type=Application
Categories=Network;RemoteAccess;
EOF

cat > "$DESKTOP_DIR/FileZilla.desktop" << 'EOF'
[Desktop Entry]
Name=FileZilla
Comment=FTP/SFTP Client
Exec=filezilla
Icon=filezilla
Type=Application
Categories=Network;FileTransfer;
EOF

cat > "$DESKTOP_DIR/Remmina.desktop" << 'EOF'
[Desktop Entry]
Name=Remmina
Comment=Remote Desktop Client
Exec=remmina
Icon=remmina
Type=Application
Categories=Network;RemoteAccess;
EOF

cat > "$DESKTOP_DIR/Wireshark.desktop" << 'EOF'
[Desktop Entry]
Name=Wireshark
Comment=Network Protocol Analyzer
Exec=wireshark
Icon=wireshark
Type=Application
Categories=Network;
EOF

# Set permissions
chmod +x "$DESKTOP_DIR"/*.desktop

# Create welcome document
cat > "$DESKTOP_DIR/INFRA-WELCOME.txt" << EOF
========================================
INFRASTRUCTURE DEPARTMENT WORKSPACE
========================================

Employee ID: ${EMPLOYEE_ID:-Not Set}
Email: ${EMPLOYEE_EMAIL:-Not Set}
Domain: ${AD_DOMAIN:-innovatech.local}

Available Tools:
----------------
- PuTTY: SSH client
- FileZilla: FTP/SFTP client
- Remmina: Remote desktop (RDP/VNC)
- Wireshark: Network analysis
- VS Code: Code editor
- AWS CLI: Cloud management
- kubectl: Kubernetes CLI
- Terraform: Infrastructure as Code
- Ansible: Configuration management

Network Utilities:
------------------
- nmap, tcpdump, traceroute, mtr
- iperf3, netcat, telnet

For support: infra-support@innovatech.local
========================================
EOF

echo "Infrastructure workspace initialized"
