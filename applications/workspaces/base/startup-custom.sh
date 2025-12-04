#!/bin/bash
# Custom startup script for workspace customization

set -e

echo "Starting workspace for employee: ${EMPLOYEE_ID:-unknown}"
echo "Department: ${DEPARTMENT:-unknown}"

# Create personalized desktop items based on department
DESKTOP_DIR="/home/kasm-user/Desktop"
mkdir -p "$DESKTOP_DIR"

# Set department-specific wallpaper
case "$DEPARTMENT" in
    "infra"|"infrastructure")
        WALLPAPER_COLOR="#1a365d"  # Dark blue
        ;;
    "dev"|"development")
        WALLPAPER_COLOR="#22543d"  # Dark green
        ;;
    "hr"|"human_resources")
        WALLPAPER_COLOR="#553c9a"  # Purple
        ;;
    *)
        WALLPAPER_COLOR="#2d3748"  # Dark gray (default)
        ;;
esac

# Create a simple wallpaper config
mkdir -p /home/kasm-user/.config

# Create welcome file
cat > "$DESKTOP_DIR/WELCOME.txt" << EOF
Welcome to Innovatech Zero Trust Workspace

Employee ID: ${EMPLOYEE_ID:-Not Set}
Department: ${DEPARTMENT:-Not Set}
Email: ${EMPLOYEE_EMAIL:-Not Set}
Domain: ${AD_DOMAIN:-innovatech.local}

This workspace is secured and monitored.
All activities are logged for security purposes.

For support, contact IT at support@innovatech.local
EOF

echo "Workspace customization completed"
