#!/bin/bash
# HR Department Startup Script
set -e

DESKTOP_DIR="/home/kasm-user/Desktop"
DOCUMENTS_DIR="/home/kasm-user/Documents"
mkdir -p "$DESKTOP_DIR" "$DOCUMENTS_DIR"

# Create desktop shortcuts for HR tools
cat > "$DESKTOP_DIR/Firefox.desktop" << 'EOF'
[Desktop Entry]
Name=Firefox
Comment=Web Browser
Exec=firefox
Icon=firefox
Type=Application
Categories=Network;WebBrowser;
EOF

cat > "$DESKTOP_DIR/Chromium.desktop" << 'EOF'
[Desktop Entry]
Name=Chromium
Comment=Web Browser
Exec=chromium-browser
Icon=chromium-browser
Type=Application
Categories=Network;WebBrowser;
EOF

cat > "$DESKTOP_DIR/LibreOffice-Writer.desktop" << 'EOF'
[Desktop Entry]
Name=LibreOffice Writer
Comment=Word Processor
Exec=libreoffice --writer
Icon=libreoffice-writer
Type=Application
Categories=Office;WordProcessor;
EOF

cat > "$DESKTOP_DIR/LibreOffice-Calc.desktop" << 'EOF'
[Desktop Entry]
Name=LibreOffice Calc
Comment=Spreadsheet
Exec=libreoffice --calc
Icon=libreoffice-calc
Type=Application
Categories=Office;Spreadsheet;
EOF

cat > "$DESKTOP_DIR/LibreOffice-Impress.desktop" << 'EOF'
[Desktop Entry]
Name=LibreOffice Impress
Comment=Presentations
Exec=libreoffice --impress
Icon=libreoffice-impress
Type=Application
Categories=Office;Presentation;
EOF

cat > "$DESKTOP_DIR/Thunderbird.desktop" << 'EOF'
[Desktop Entry]
Name=Thunderbird
Comment=Email Client
Exec=thunderbird
Icon=thunderbird
Type=Application
Categories=Network;Email;
EOF

cat > "$DESKTOP_DIR/PDF-Viewer.desktop" << 'EOF'
[Desktop Entry]
Name=Document Viewer
Comment=PDF Viewer
Exec=evince
Icon=evince
Type=Application
Categories=Office;Viewer;
EOF

cat > "$DESKTOP_DIR/File-Manager.desktop" << 'EOF'
[Desktop Entry]
Name=Files
Comment=File Manager
Exec=thunar
Icon=system-file-manager
Type=Application
Categories=System;FileManager;
EOF

cat > "$DESKTOP_DIR/Calculator.desktop" << 'EOF'
[Desktop Entry]
Name=Calculator
Comment=Calculator
Exec=gnome-calculator
Icon=accessories-calculator
Type=Application
Categories=Utility;Calculator;
EOF

# Set permissions
chmod +x "$DESKTOP_DIR"/*.desktop

# Create HR document templates
mkdir -p "$DOCUMENTS_DIR/Templates"

# Create sample documents
cat > "$DOCUMENTS_DIR/Templates/Employee-Onboarding-Checklist.txt" << 'EOF'
EMPLOYEE ONBOARDING CHECKLIST
=============================

Employee Name: ________________
Start Date: ________________
Department: ________________

[ ] Welcome packet sent
[ ] Workstation assigned
[ ] Email account created
[ ] AD account created
[ ] Security badge issued
[ ] IT equipment provided
[ ] Orientation scheduled
[ ] Manager introduction
[ ] Team introduction
[ ] Policy handbook provided
[ ] Benefits enrollment
[ ] Emergency contact form
[ ] Direct deposit form

Completed by: ________________
Date: ________________
EOF

cat > "$DOCUMENTS_DIR/Templates/Leave-Request-Form.txt" << 'EOF'
LEAVE REQUEST FORM
==================

Employee Name: ________________
Employee ID: ________________
Department: ________________

Leave Type:
[ ] Annual Leave
[ ] Sick Leave
[ ] Personal Leave
[ ] Other: ________________

Start Date: ________________
End Date: ________________
Total Days: ________________

Reason (if applicable):
_________________________________
_________________________________

Employee Signature: ________________
Date: ________________

Manager Approval: ________________
Date: ________________
EOF

# Create welcome document
cat > "$DESKTOP_DIR/HR-WELCOME.txt" << EOF
========================================
HR DEPARTMENT WORKSPACE
========================================

Employee ID: ${EMPLOYEE_ID:-Not Set}
Email: ${EMPLOYEE_EMAIL:-Not Set}
Domain: ${AD_DOMAIN:-innovatech.local}

Available Applications:
-----------------------
- Firefox & Chromium: Web browsers
- Thunderbird: Email client
- LibreOffice Writer: Word processing
- LibreOffice Calc: Spreadsheets
- LibreOffice Impress: Presentations
- Document Viewer: PDF viewing
- PDF Arranger: PDF editing

File Locations:
---------------
- Documents: /home/kasm-user/Documents
- Downloads: /home/kasm-user/Downloads
- Templates: /home/kasm-user/Documents/Templates

HR Portal Access:
-----------------
Open Firefox and navigate to:
http://hrportal.innovatech.local:30080

For support: hr-support@innovatech.local
========================================
EOF

echo "HR workspace initialized"
