#!/bin/bash
# Development Department Startup Script
set -e

DESKTOP_DIR="/home/kasm-user/Desktop"
PROJECTS_DIR="/home/kasm-user/projects"
mkdir -p "$DESKTOP_DIR" "$PROJECTS_DIR"

# Create desktop shortcuts for development tools
cat > "$DESKTOP_DIR/VS-Code.desktop" << 'EOF'
[Desktop Entry]
Name=Visual Studio Code
Comment=Code Editor
Exec=/usr/share/code/code --no-sandbox
Icon=vscode
Type=Application
Categories=Development;IDE;
EOF

cat > "$DESKTOP_DIR/Terminal.desktop" << 'EOF'
[Desktop Entry]
Name=Terminal
Comment=Terminal Emulator
Exec=xfce4-terminal
Icon=utilities-terminal
Type=Application
Categories=System;TerminalEmulator;
EOF

cat > "$DESKTOP_DIR/GitK.desktop" << 'EOF'
[Desktop Entry]
Name=GitK
Comment=Git Repository Browser
Exec=gitk
Icon=git
Type=Application
Categories=Development;RevisionControl;
EOF

cat > "$DESKTOP_DIR/Meld.desktop" << 'EOF'
[Desktop Entry]
Name=Meld
Comment=Diff and Merge Tool
Exec=meld
Icon=meld
Type=Application
Categories=Development;
EOF

# Set permissions
chmod +x "$DESKTOP_DIR"/*.desktop

# Configure git for the user
if [ -n "$EMPLOYEE_EMAIL" ]; then
    git config --global user.email "$EMPLOYEE_EMAIL"
fi
if [ -n "$EMPLOYEE_ID" ]; then
    git config --global user.name "Employee $EMPLOYEE_ID"
fi

# Create sample project structure
mkdir -p "$PROJECTS_DIR/sample-project"
cat > "$PROJECTS_DIR/sample-project/README.md" << 'EOF'
# Sample Project

This is a sample project structure for development work.

## Getting Started

1. Clone your repository into /home/kasm-user/projects/
2. Open VS Code and start coding
3. Use the terminal for git operations

## Available Tools

- VS Code with extensions
- Node.js 20.x with npm, yarn, pnpm
- Python 3 with pip, virtualenv
- Java 17 with Maven, Gradle
- Docker CLI
- kubectl for Kubernetes
- AWS CLI

Happy coding!
EOF

# Create welcome document
cat > "$DESKTOP_DIR/DEV-WELCOME.txt" << EOF
========================================
DEVELOPMENT DEPARTMENT WORKSPACE
========================================

Employee ID: ${EMPLOYEE_ID:-Not Set}
Email: ${EMPLOYEE_EMAIL:-Not Set}
Domain: ${AD_DOMAIN:-innovatech.local}

Development Tools:
------------------
- VS Code: Full-featured IDE
- Git: Version control with LFS support
- GitK: Visual repository browser
- Meld: Diff and merge tool

Languages & Runtimes:
---------------------
- Node.js 20.x (npm, yarn, pnpm)
- Python 3 (pip, virtualenv)
- Java 17 (Maven, Gradle)

DevOps Tools:
-------------
- Docker CLI
- kubectl
- AWS CLI

Database Clients:
-----------------
- PostgreSQL client
- MySQL client
- Redis client

Project Directory: /home/kasm-user/projects/

For support: dev-support@innovatech.local
========================================
EOF

echo "Development workspace initialized"
