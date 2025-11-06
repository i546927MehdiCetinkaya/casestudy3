# Deployment Fixes - GitHub Actions Issues

## Issues Identified from Workflow Run

### 1. ❌ Kubernetes Namespace Missing
**Error:**
```
Error from server (NotFound): error when creating "kubernetes/rbac.yaml": namespaces "workspaces" not found
Error from server (NotFound): error when creating "kubernetes/rbac.yaml": namespaces "workspaces" not found
```

**Root Cause:**
- RBAC resources (Roles, RoleBindings) were being created before the required namespaces existed
- The `workspaces` namespace was defined in `workspaces.yaml` but applied AFTER `rbac.yaml`

**Fix Applied:**
1. Created new `kubernetes/namespaces.yaml` to define all namespaces upfront:
   - `hr-portal` namespace
   - `workspaces` namespace
2. Updated deployment workflow to apply namespaces FIRST:
   ```yaml
   - name: Deploy Namespaces
     run: kubectl apply -f kubernetes/namespaces.yaml
   - name: Deploy RBAC
     run: kubectl apply -f kubernetes/rbac.yaml
   ```
3. Removed duplicate namespace definition from `workspaces.yaml`

---

### 2. ❌ Docker Build Failed - GID Conflict
**Error:**
```
#9 0.254 addgroup: gid '1000' in use
ERROR: failed to build: process "/bin/sh -c addgroup -g 1000 nodeapp && adduser -u 1000 -G nodeapp -s /bin/sh -D nodeapp" did not complete successfully: exit code: 1
```

**Root Cause:**
- Alpine Linux base image (node:18-alpine) already has a group with GID 1000 (typically the 'node' group)
- Our Dockerfile tried to create a new group with the same GID, causing a conflict

**Fix Applied:**
Changed `applications/hr-portal/backend/Dockerfile`:
```dockerfile
# Before:
RUN addgroup -g 1000 nodeapp && adduser -u 1000 -G nodeapp -s /bin/sh -D nodeapp

# After:
RUN addgroup -g 1001 nodeapp && adduser -u 1001 -G nodeapp -s /bin/sh -D nodeapp
```

**Why GID 1001 Works:**
- GID/UID 1001 is not used by the Alpine base image
- Still maintains security best practices (non-root user)
- Kubernetes securityContext can still use UID 1001

---

### 3. ❌ Sequential Failures
**Impact:**
```
Terraform: success ✅
Kubernetes: failure ❌
Container Images: failure ❌
Tests: skipped ⏭️
```

**Root Cause:**
- Kubernetes deployment failed due to namespace issue
- Container image builds failed because they depend on Kubernetes being ready
- Tests were skipped because previous stages failed

**Fix Applied:**
With the above two fixes, the deployment sequence should work correctly:
1. ✅ Terraform creates AWS infrastructure (EKS, VPC, etc.)
2. ✅ Namespaces are created first
3. ✅ RBAC resources can now reference existing namespaces
4. ✅ Container images build successfully with GID 1001
5. ✅ Tests can run after successful deployment

---

## Verification Steps

After committing these fixes, the workflow should succeed:

```bash
# 1. Commit all fixes
git add .
git commit -m "Fix: Resolve namespace ordering and Docker GID conflicts"
git push

# 2. Monitor GitHub Actions workflow
# Navigate to: https://github.com/i546927MehdiCetinkaya/casestudy3/actions

# 3. Verify successful deployment
# All stages should show green checkmarks:
# - Validate Configuration ✅
# - Terraform Plan ✅
# - Deploy Terraform Infrastructure ✅
# - Deploy Kubernetes Resources ✅
# - Build and Push Container Images ✅
# - Post-Deployment Tests ✅
# - Notify ✅
```

---

## Files Modified

1. **Created:** `kubernetes/namespaces.yaml`
   - Centralized namespace definitions
   - Applied before all other Kubernetes resources

2. **Modified:** `applications/hr-portal/backend/Dockerfile`
   - Changed GID/UID from 1000 to 1001
   - Avoids conflict with Alpine base image

3. **Modified:** `.github/workflows/deploy.yml`
   - Added namespace validation step
   - Added namespace deployment step before RBAC
   - Ensures correct resource creation order

4. **Modified:** `kubernetes/workspaces.yaml`
   - Removed duplicate namespace definition
   - Now relies on centralized namespaces.yaml

---

## Best Practices Learned

1. **Kubernetes Resource Ordering:**
   - Always create namespaces first
   - Then create service accounts and RBAC
   - Finally create workloads (pods, deployments, services)

2. **Docker User Management:**
   - Check base image for existing GID/UID conflicts
   - Use `docker run --rm <image> cat /etc/passwd` to inspect
   - Common GIDs to avoid: 1000 (node), 999 (docker), 0 (root)

3. **CI/CD Validation:**
   - Validate Kubernetes manifests with tools like kubeconform
   - Test Docker builds locally before pushing to CI
   - Use `kubectl apply --dry-run=client` to test manifests

---

## Testing Checklist

After deployment succeeds, verify:

- [ ] All namespaces created: `kubectl get namespaces`
- [ ] RBAC resources exist: `kubectl get clusterroles,clusterrolebindings`
- [ ] Pods are running: `kubectl get pods -A`
- [ ] Container images pushed to ECR: Check AWS Console
- [ ] Applications are accessible: Test ingress endpoints
- [ ] No security violations: Review pod security contexts

---

## Emergency Rollback

If issues persist, use the destroy workflow:

```bash
# Navigate to GitHub Actions
# Run "Destroy Infrastructure" workflow
# Type "destroy" in the confirmation input
# This will safely tear down all resources
```

---

**Date:** 2025-11-06  
**Status:** ✅ Fixes Applied - Ready for Testing  
**Next Action:** Push to GitHub and monitor workflow execution
