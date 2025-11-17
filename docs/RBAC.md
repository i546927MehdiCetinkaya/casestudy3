# Role-Based Access Control (RBAC) Implementation

## Overview

Dit project implementeert RBAC op drie niveaus:
1. **Kubernetes RBAC** - Namespace en pod-level permissions
2. **Backend RBAC** - API endpoint permissions
3. **Workspace RBAC** - Folder-level permissions per rol

---

## Roles & Permissions

### Admin
**Toegang**: Alle afdelingen en resources

**Permissions**:
- ✅ Alle employees lezen/schrijven/verwijderen
- ✅ Alle workspaces beheren
- ✅ Alle folders toegang
- ✅ Alle departments beheren

**Folders**:
```
/workspace
  ├── /personal/              (read/write)
  ├── /departments/           (read/write alle)
  │   ├── /hr/
  │   ├── /engineering/
  │   ├── /sales/
  │   ├── /marketing/
  │   └── /operations/
  └── /shared/                (read/write alle)
```

---

### Manager
**Toegang**: Eigen afdeling + read-only andere afdelingen

**Permissions**:
- ✅ Eigen department employees lezen/schrijven
- 👁️ Andere departments read-only
- ✅ Eigen department workspaces bekijken
- ❌ Geen delete permissions

**Folders**:
```
/workspace
  ├── /personal/                    (read/write)
  ├── /departments/engineering/     (read/write eigen dept)
  ├── /departments/hr/              (read-only andere)
  └── /departments/sales/           (read-only andere)
```

---

### Developer
**Toegang**: Eigen workspace + read-only department

**Permissions**:
- ✅ Eigen profile lezen
- 👁️ Department employees read-only
- ✅ Eigen workspace read/write
- ❌ Geen andere workspaces

**Folders**:
```
/workspace
  ├── /personal/                (read/write)
  ├── /departments/engineering/ (read-only)
  └── /projects/                (read/write)
```

---

### Sales/Marketing/Operations
**Toegang**: Eigen afdeling + shared folder

**Permissions**:
- ✅ Eigen profile lezen
- 👁️ Department read-only
- ✅ Shared department folder

**Folders (Sales example)**:
```
/workspace
  ├── /personal/            (read/write)
  ├── /departments/sales/   (read/write)
  └── /shared/sales/        (read/write)
```

---

## Implementation

### 1. Kubernetes RBAC

File: `kubernetes/rbac-departments.yaml`

- Namespaces per department
- ServiceAccounts met specifieke roles
- RoleBindings voor permission enforcement

**Deploy**:
```bash
kubectl apply -f kubernetes/rbac-departments.yaml
```

---

### 2. Backend RBAC Service

File: `applications/hr-portal/backend/src/services/rbac.js`

**Functions**:
```javascript
// Check permission
const { allowed, reason } = await checkPermission(
  employeeId, 
  'read', 
  'employee', 
  targetEmployeeId
);

// Middleware
router.get('/employees/:id', 
  requirePermission('employee', 'read'),
  async (req, res) => { ... }
);
```

**API Headers**:
```
X-Employee-Id: current-employee-id
X-Employee-Role: manager
X-Employee-Department: Engineering
```

---

### 3. Workspace Folder Permissions

File: `applications/workspace/init-rbac.sh`

**Startup Process**:
1. Container start met environment variables
2. `init-rbac.sh` script runs
3. Folders worden aangemaakt met juiste permissions
4. README wordt gegenereerd met access info
5. Code-server start met configured workspace

**Environment Variables**:
```yaml
env:
- name: EMPLOYEE_ID
  value: "john-doe"
- name: EMPLOYEE_ROLE
  value: "developer"
- name: EMPLOYEE_DEPARTMENT
  value: "Engineering"
```

---

## Usage Examples

### Example 1: Manager toegang

**Request**:
```bash
curl -H "X-Employee-Id: manager-123" \
     -H "X-Employee-Role: manager" \
     -H "X-Employee-Department: Engineering" \
     http://api/employees
```

**Response**:
```json
{
  "employees": [
    { "employeeId": "dev-1", "department": "Engineering" },
    { "employeeId": "dev-2", "department": "Engineering" }
  ],
  "rbac": {
    "role": "manager",
    "department": "Engineering",
    "permissions": {
      "departments": ["own"],
      "employees": { "read": true, "write": true, "delete": false }
    }
  }
}
```

---

### Example 2: Developer folder access

**Workspace folders bij start**:
```
/home/coder/workspace/
├── README.md                     (permission info)
├── personal/                     (700 - full access)
├── departments/
│   └── engineering/              (550 - read-only)
└── projects/                     (750 - read/write)
```

**Trying to write to department folder**:
```bash
$ cd /home/coder/workspace/departments/engineering
$ touch test.txt
Permission denied
```

**Writing to personal folder**:
```bash
$ cd /home/coder/workspace/personal
$ touch myfile.txt
✓ Success
```

---

## Testing RBAC

### Test 1: Employee Access
```bash
# As Admin - should see all
curl -H "X-Employee-Id: admin-1" http://api/employees

# As Manager - should see department only
curl -H "X-Employee-Id: manager-1" \
     -H "X-Employee-Department: Engineering" \
     http://api/employees

# As Developer - should see error
curl -H "X-Employee-Id: dev-1" http://api/employees
# Response: 403 Forbidden
```

### Test 2: Workspace Folders
```bash
# Deploy test workspace
kubectl apply -f kubernetes/workspaces.yaml

# Check folder permissions
kubectl exec -it john-doe-workspace -n workspaces -- ls -la /home/coder/workspace

# View README with permission info
kubectl exec -it john-doe-workspace -n workspaces -- cat /home/coder/workspace/README.md
```

---

## Security Considerations

### ✅ Implemented:
- Kubernetes namespace isolation
- Pod SecurityContext (non-root, no privilege escalation)
- Backend permission checks op alle endpoints
- Folder-level permissions met Linux file permissions
- DynamoDB query filtering per department

### 🔒 Additional Recommendations:
- Add AWS Cognito voor SSO authentication
- Implement JWT tokens voor API calls
- Add audit logging voor permission checks
- Network policies tussen namespaces
- Encryption at rest voor persistent volumes

---

## Troubleshooting

### Issue: Permission denied in workspace
```bash
# Check current user permissions
whoami
# Should be: coder

# Check folder permissions
ls -la /home/coder/workspace/

# Check environment variables
env | grep EMPLOYEE
```

### Issue: API returns 403 Forbidden
```bash
# Check headers sent
curl -v -H "X-Employee-Id: xxx" http://api/endpoint

# Check employee exists
kubectl exec -it hr-portal-backend-xxx -- \
  curl http://localhost:3000/api/employees/xxx
```

### Issue: Cannot access department namespace
```bash
# Check RBAC roles
kubectl get roles -n dept-engineering

# Check role binding
kubectl get rolebindings -n dept-engineering

# Test service account permissions
kubectl auth can-i list pods --as=system:serviceaccount:dept-engineering:engineering-service-account -n dept-engineering
```

---

## Future Enhancements

1. **SSO Integration** (AWS Cognito)
   - OAuth2/OIDC flow
   - JWT token validation
   - Automatic role assignment

2. **Audit Logging**
   - Log all permission checks
   - Track file access in workspaces
   - CloudWatch integration

3. **Fine-grained Permissions**
   - File-level permissions
   - Time-based access
   - IP restrictions

4. **Self-service Access Requests**
   - Request access to other departments
   - Manager approval workflow
   - Temporary access grants
