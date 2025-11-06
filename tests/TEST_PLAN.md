# Test Plan - Employee Lifecycle Automation System

## Overview
This document outlines the comprehensive testing strategy for the Employee Lifecycle Automation system on AWS EKS.

## Test Categories

### 1. Infrastructure Tests

#### 1.1 Terraform Validation
**Objective**: Verify infrastructure is deployed correctly

**Tests**:
- [ ] `terraform validate` passes without errors
- [ ] `terraform plan` shows no unexpected changes
- [ ] All outputs are correctly generated
- [ ] Resources are tagged appropriately

**Commands**:
```powershell
cd terraform
terraform validate
terraform plan
terraform output
```

#### 1.2 VPC Verification
**Objective**: Ensure network infrastructure is correct

**Tests**:
- [ ] VPC created with correct CIDR (10.0.0.0/16)
- [ ] 3 public subnets created
- [ ] 3 private subnets created
- [ ] NAT gateways operational in each AZ
- [ ] VPC endpoints created and functional

**Commands**:
```powershell
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*innovatech*"
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<vpc-id>"
aws ec2 describe-nat-gateways
aws ec2 describe-vpc-endpoints
```

#### 1.3 EKS Cluster Verification
**Objective**: Validate EKS cluster health

**Tests**:
- [ ] EKS cluster status is ACTIVE
- [ ] Control plane accessible
- [ ] 3 worker nodes running
- [ ] Nodes span multiple AZs
- [ ] Cluster add-ons installed (VPC CNI, CoreDNS, kube-proxy)

**Commands**:
```powershell
aws eks describe-cluster --name innovatech-employee-lifecycle
kubectl get nodes -o wide
kubectl get pods -n kube-system
```

---

### 2. Application Tests

#### 2.1 HR Portal Deployment
**Objective**: Verify HR Portal is running correctly

**Tests**:
- [ ] Namespace `hr-portal` exists
- [ ] 2 backend pods running
- [ ] 2 frontend pods running
- [ ] Services created (ClusterIP)
- [ ] Ingress created with ALB
- [ ] Health check endpoints responding

**Commands**:
```powershell
kubectl get all -n hr-portal
kubectl describe ingress -n hr-portal
kubectl logs -n hr-portal -l app=hr-portal-backend --tail=50
```

#### 2.2 API Functionality
**Objective**: Test HR Portal API endpoints

**Test Cases**:

**Test 2.2.1: Health Check**
```powershell
curl -X GET https://hr.innovatech.example.com/api/health
# Expected: {"status":"healthy"}
```

**Test 2.2.2: Create Employee**
```powershell
$body = @{
    firstName = "Test"
    lastName = "User"
    email = "test.user@innovatech.com"
    role = "developer"
    department = "Engineering"
} | ConvertTo-Json

curl -X POST https://hr.innovatech.example.com/api/employees `
  -H "Content-Type: application/json" `
  -d $body
# Expected: 201 Created with employee data
```

**Test 2.2.3: Get All Employees**
```powershell
curl -X GET https://hr.innovatech.example.com/api/employees
# Expected: JSON array of employees
```

**Test 2.2.4: Update Employee**
```powershell
$body = @{
    department = "Data Science"
} | ConvertTo-Json

curl -X PUT https://hr.innovatech.example.com/api/employees/<employee-id> `
  -H "Content-Type: application/json" `
  -d $body
# Expected: 200 OK
```

**Test 2.2.5: Delete Employee (Offboarding)**
```powershell
curl -X DELETE https://hr.innovatech.example.com/api/employees/<employee-id>
# Expected: 200 OK, workspace deprovisioning message
```

#### 2.3 Workspace Provisioning
**Objective**: Verify workspace creation and access

**Tests**:
- [ ] Pod created in `workspaces` namespace
- [ ] PVC bound to EBS volume
- [ ] Secret created with credentials
- [ ] Service created
- [ ] Ingress created with unique subdomain
- [ ] Workspace accessible via URL
- [ ] VS Code interface loads
- [ ] Persistent storage functional

**Commands**:
```powershell
kubectl get pods -n workspaces
kubectl get pvc -n workspaces
kubectl describe pod <workspace-pod> -n workspaces
# Access: https://<firstname-lastname>.workspaces.innovatech.example.com
```

---

### 3. Security Tests

#### 3.1 Network Policy Verification
**Objective**: Ensure Zero Trust network segmentation

**Tests**:

**Test 3.1.1: Default Deny**
```powershell
# Attempt to access backend from unauthorized pod (should fail)
kubectl run test-pod --image=busybox -n default --rm -it -- wget -O- http://hr-portal-backend.hr-portal
# Expected: Connection timeout or refused
```

**Test 3.1.2: Frontend to Backend Communication**
```powershell
# From frontend pod, should be able to reach backend
kubectl exec -n hr-portal <frontend-pod> -- wget -O- http://hr-portal-backend:80
# Expected: Success
```

**Test 3.1.3: Workspace Isolation**
```powershell
# From one workspace, try to reach another (should fail)
kubectl exec -n workspaces <workspace-1> -- wget -O- http://<workspace-2>.workspaces
# Expected: Connection refused
```

#### 3.2 RBAC Verification
**Objective**: Validate role-based access control

**Tests**:
- [ ] HR Portal backend can create/delete workspaces
- [ ] Regular service accounts cannot access HR Portal namespace
- [ ] Workspace provisioner has correct permissions

**Commands**:
```powershell
kubectl auth can-i create pods --as=system:serviceaccount:hr-portal:hr-portal-backend -n workspaces
# Expected: yes

kubectl auth can-i create pods --as=system:serviceaccount:default:default -n workspaces
# Expected: no
```

#### 3.3 Encryption Verification
**Objective**: Ensure data is encrypted at rest and in transit

**Tests**:
- [ ] EBS volumes encrypted
- [ ] DynamoDB encryption enabled
- [ ] Secrets encrypted with KMS
- [ ] TLS on ALB (HTTPS)

**Commands**:
```powershell
aws ec2 describe-volumes --filters "Name=tag:kubernetes.io/cluster/innovatech-employee-lifecycle,Values=*"
aws dynamodb describe-table --table-name innovatech-employees | jq .Table.SSEDescription
kubectl describe secret -n hr-portal
```

---

### 4. Scalability Tests

#### 4.1 Horizontal Pod Autoscaling
**Objective**: Test auto-scaling behavior

**Tests**:
- [ ] Increase load on HR Portal
- [ ] Observe pod scaling
- [ ] Verify performance under load

**Commands**:
```powershell
# Apply load
kubectl run -n hr-portal load-generator --image=busybox --rm -it -- /bin/sh -c "while true; do wget -q -O- http://hr-portal-backend; done"

# Monitor
kubectl get hpa -n hr-portal -w
kubectl top pods -n hr-portal
```

#### 4.2 Node Auto-Scaling
**Objective**: Test EKS node group scaling

**Tests**:
- [ ] Create many workspaces to trigger node scaling
- [ ] Verify new nodes are added
- [ ] Verify nodes are in multiple AZs

**Commands**:
```powershell
# Create multiple employees (triggers workspace provisioning)
for ($i=1; $i -le 20; $i++) {
    # API call to create employee
}

kubectl get nodes -o wide
aws autoscaling describe-auto-scaling-groups
```

---

### 5. High Availability Tests

#### 5.1 Pod Failure Recovery
**Objective**: Verify pod self-healing

**Test**:
```powershell
# Delete a pod
kubectl delete pod -n hr-portal <backend-pod>

# Verify it's recreated
kubectl get pods -n hr-portal -w
# Expected: New pod starts automatically
```

#### 5.2 Node Failure Simulation
**Objective**: Verify workload migration

**Test**:
```powershell
# Drain a node
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Verify pods moved to other nodes
kubectl get pods -n hr-portal -o wide
kubectl get pods -n workspaces -o wide

# Uncordon node
kubectl uncordon <node-name>
```

---

### 6. Data Integrity Tests

#### 6.1 DynamoDB Operations
**Objective**: Verify data persistence

**Tests**:
- [ ] Create employee record
- [ ] Retrieve employee record
- [ ] Update employee record
- [ ] Verify changes persisted
- [ ] Delete employee record

**Commands**:
```powershell
# Via API (see Section 2.2)
# Or directly:
aws dynamodb get-item --table-name innovatech-employees --key '{"employeeId":{"S":"<id>"}}'
```

#### 6.2 Workspace Storage Persistence
**Objective**: Verify PVC data survives pod restarts

**Test**:
```powershell
# Create file in workspace
kubectl exec -n workspaces <workspace-pod> -- sh -c "echo 'test' > /home/coder/workspace/test.txt"

# Delete pod (simulates crash)
kubectl delete pod -n workspaces <workspace-pod>

# Wait for pod to restart, verify file exists
kubectl exec -n workspaces <new-workspace-pod> -- cat /home/coder/workspace/test.txt
# Expected: "test"
```

---

### 7. Performance Tests

#### 7.1 API Response Times
**Objective**: Measure API performance

**Test**:
```powershell
# Measure response time
Measure-Command { curl -X GET https://hr.innovatech.example.com/api/employees }
# Expected: < 500ms
```

#### 7.2 Workspace Provisioning Time
**Objective**: Measure workspace creation speed

**Test**:
- [ ] Create employee
- [ ] Measure time until workspace URL is accessible
- **Target**: < 2 minutes

#### 7.3 Concurrent User Load
**Objective**: Test system under concurrent load

**Test**:
- Simulate 50 concurrent API requests
- Monitor CPU, memory, and response times
- Verify no failures

---

### 8. Disaster Recovery Tests

#### 8.1 DynamoDB Point-in-Time Recovery
**Objective**: Verify backup and restore capability

**Test**:
```powershell
# Verify PITR is enabled
aws dynamodb describe-continuous-backups --table-name innovatech-employees

# Simulate recovery (don't run in production!)
# aws dynamodb restore-table-to-point-in-time ...
```

#### 8.2 Workspace Backup
**Objective**: Verify EBS snapshots

**Test**:
```powershell
# Create snapshot of workspace volume
$volumeId = kubectl get pvc -n workspaces <pvc-name> -o jsonpath='{.spec.volumeName}'
aws ec2 create-snapshot --volume-id $volumeId --description "Test snapshot"
```

---

### 9. Monitoring & Logging Tests

#### 9.1 CloudWatch Logs
**Objective**: Verify logs are collected

**Tests**:
- [ ] EKS cluster logs available
- [ ] Application logs available
- [ ] VPC Flow Logs available

**Commands**:
```powershell
aws logs describe-log-groups --log-group-name-prefix "/aws/eks/innovatech"
aws logs tail /aws/eks/innovatech-employee-lifecycle/cluster --follow
```

#### 9.2 CloudWatch Metrics
**Objective**: Verify metrics collection

**Tests**:
- [ ] EKS metrics visible
- [ ] Custom metrics from application
- [ ] Dashboard displays correctly

**Commands**:
```powershell
aws cloudwatch list-metrics --namespace AWS/EKS
# View dashboard in AWS Console
```

---

### 10. Compliance Tests

#### 10.1 Security Group Audit
**Objective**: Verify least privilege network access

**Test**:
- [ ] No security group allows 0.0.0.0/0 on SSH (port 22)
- [ ] Only ALB security group allows internet HTTPS
- [ ] Node security groups only allow necessary ports

#### 10.2 IAM Policy Audit
**Objective**: Verify least privilege IAM permissions

**Test**:
- [ ] HR Portal role only has DynamoDB permissions
- [ ] Workspace role only has CloudWatch permissions
- [ ] No overly broad permissions (*:*)

**Commands**:
```powershell
aws iam get-role-policy --role-name innovatech-employee-lifecycle-hr-portal-role --policy-name dynamodb-access
```

---

## Test Execution Checklist

### Pre-Deployment Tests
- [ ] Terraform validate
- [ ] Terraform plan review
- [ ] Cost estimation review

### Post-Deployment Tests
- [ ] Infrastructure verification (Section 1)
- [ ] Application smoke tests (Section 2.1, 2.2)
- [ ] Security baseline tests (Section 3.1, 3.2)

### Functional Tests
- [ ] Full employee lifecycle (create, update, delete)
- [ ] Workspace provisioning and access
- [ ] API all endpoints

### Non-Functional Tests
- [ ] Performance tests (Section 7)
- [ ] Scalability tests (Section 4)
- [ ] High availability tests (Section 5)

### Production Readiness
- [ ] Monitoring configured
- [ ] Alerts configured
- [ ] Backup procedures tested
- [ ] Disaster recovery plan documented

---

## Test Results Template

### Test Execution Date: [DATE]
### Tester: [NAME]
### Environment: [Production/Staging/Dev]

| Test ID | Test Name | Status | Notes |
|---------|-----------|--------|-------|
| 1.1 | Terraform Validation | ✅ Pass | |
| 1.2 | VPC Verification | ✅ Pass | |
| ... | ... | ... | |

### Summary
- Total Tests: X
- Passed: Y
- Failed: Z
- Blocked: W

### Issues Found
1. [Issue description]
2. [Issue description]

### Recommendations
1. [Recommendation]
2. [Recommendation]

---

**Document Version**: 1.0.0  
**Last Updated**: November 6, 2025