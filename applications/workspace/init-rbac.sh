#!/bin/bash
# RBAC Initialization Script for Workspace
# This script runs when workspace container starts
# Sets up folder permissions based on employee role

set -e

echo "🔐 Initializing RBAC for workspace..."

# Get employee info from environment variables
EMPLOYEE_ID="${EMPLOYEE_ID:-unknown}"
EMPLOYEE_ROLE="${EMPLOYEE_ROLE:-developer}"
EMPLOYEE_DEPT="${EMPLOYEE_DEPARTMENT:-Engineering}"

echo "Employee: $EMPLOYEE_ID"
echo "Role: $EMPLOYEE_ROLE"
echo "Department: $EMPLOYEE_DEPT"

# Create base directory structure
WORKSPACE_ROOT="/home/coder/workspace"
mkdir -p "$WORKSPACE_ROOT"

# Create personal folder (always accessible)
PERSONAL_DIR="$WORKSPACE_ROOT/personal"
mkdir -p "$PERSONAL_DIR"
chmod 700 "$PERSONAL_DIR"
echo "✓ Created personal folder: $PERSONAL_DIR"

# Create department folder based on role
DEPT_DIR="$WORKSPACE_ROOT/departments/${EMPLOYEE_DEPT,,}"
mkdir -p "$DEPT_DIR"

case "$EMPLOYEE_ROLE" in
  admin)
    # Admin has full access to everything
    chmod 777 "$DEPT_DIR"
    
    # Create shared folders for all departments
    for dept in hr engineering sales marketing operations; do
      SHARED_DIR="$WORKSPACE_ROOT/shared/$dept"
      mkdir -p "$SHARED_DIR"
      chmod 777 "$SHARED_DIR"
      echo "✓ Created shared folder: $SHARED_DIR (full access)"
    done
    
    echo "✓ Admin: Full access to all folders"
    ;;
    
  manager)
    # Manager has read/write to department folder
    chmod 770 "$DEPT_DIR"
    
    # Read-only to other departments
    for dept in hr engineering sales marketing operations; do
      if [ "$dept" != "${EMPLOYEE_DEPT,,}" ]; then
        OTHER_DEPT_DIR="$WORKSPACE_ROOT/departments/$dept"
        mkdir -p "$OTHER_DEPT_DIR"
        chmod 550 "$OTHER_DEPT_DIR"
      fi
    done
    
    echo "✓ Manager: Read/write access to $EMPLOYEE_DEPT, read-only to others"
    ;;
    
  developer)
    # Developer has read-only to department folder
    chmod 550 "$DEPT_DIR"
    
    # Create project folders with appropriate permissions
    PROJECT_DIR="$WORKSPACE_ROOT/projects"
    mkdir -p "$PROJECT_DIR"
    chmod 750 "$PROJECT_DIR"
    
    echo "✓ Developer: Read-only department access, personal projects folder"
    ;;
    
  sales|marketing|operations)
    # Department-specific access
    chmod 750 "$DEPT_DIR"
    
    # Shared folder for department
    SHARED_DEPT_DIR="$WORKSPACE_ROOT/shared/${EMPLOYEE_ROLE}"
    mkdir -p "$SHARED_DEPT_DIR"
    chmod 770 "$SHARED_DEPT_DIR"
    
    echo "✓ $EMPLOYEE_ROLE: Department and shared folder access"
    ;;
    
  *)
    # Default: minimal access
    chmod 550 "$DEPT_DIR"
    echo "⚠️  Unknown role: minimal access granted"
    ;;
esac

# Create README files explaining folder structure
cat > "$WORKSPACE_ROOT/README.md" << EOF
# Workspace Folder Structure

## Your Access (Role: $EMPLOYEE_ROLE, Department: $EMPLOYEE_DEPT)

### 📁 Personal Folder
\`$PERSONAL_DIR\`
- **Access**: Full read/write access
- **Purpose**: Your private files and configurations

### 📂 Department Folder
\`$DEPT_DIR\`
- **Access**: $([ "$EMPLOYEE_ROLE" = "admin" ] && echo "Full access" || [ "$EMPLOYEE_ROLE" = "manager" ] && echo "Read/write" || echo "Read-only")
- **Purpose**: Department-wide shared files

### 🔒 RBAC Permissions

#### Admin
- ✅ Full access to all folders
- ✅ Can manage all departments
- ✅ Can modify any file

#### Manager
- ✅ Full access to own department
- 👁️  Read-only access to other departments
- ❌ Cannot modify other departments

#### Developer
- 👁️  Read-only access to department
- ✅ Full access to personal folder
- ✅ Full access to projects folder
- ❌ Cannot modify department files

#### Sales/Marketing/Operations
- ✅ Access to own department folder
- ✅ Access to shared department folder
- 👁️  Read-only to personal projects

---
**Folder Permissions Initialized**: $(date)
**Employee ID**: $EMPLOYEE_ID
EOF

echo "✓ Created README with permissions info"

# Set ownership
chown -R coder:coder "$WORKSPACE_ROOT"

echo "🎉 RBAC initialization complete!"
echo ""
echo "Folder structure:"
tree -L 2 "$WORKSPACE_ROOT" || ls -la "$WORKSPACE_ROOT"

# Start code-server with environment variables
exec code-server --bind-addr 0.0.0.0:8080 "$WORKSPACE_ROOT"
