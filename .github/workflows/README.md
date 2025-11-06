# GitHub Actions CI/CD Documentation

This directory contains GitHub Actions workflows for automating the deployment, destruction, and validation of the Employee Lifecycle Automation infrastructure.

## Workflows

### 1. Deploy Infrastructure (`deploy.yml`)

**Trigger**: 
- Manual (`workflow_dispatch`)
- Push to `main` branch (paths: terraform, kubernetes)

**Environments**: dev, staging, production

**Jobs**:
1. **validate**: Validates Terraform and Kubernetes configurations
2. **plan**: Creates Terraform plan
3. **approval**: Manual approval for production (optional)
4. **deploy-infrastructure**: Applies Terraform
5. **deploy-kubernetes**: Deploys K8s resources
6. **build-images**: Builds and pushes Docker images to ECR
7. **post-deployment-tests**: Runs health checks
8. **notify**: Sends deployment summary

**Usage**:
```bash
# Go to Actions tab in GitHub
# Select "Deploy Infrastructure"
# Click "Run workflow"
# Choose environment: dev/staging/production
# Optionally skip approval for testing
```

---

### 2. Destroy Infrastructure (`destroy.yml`)

**Trigger**: Manual only (`workflow_dispatch`)

**Environments**: dev, staging, production

**Jobs**:
1. **validate-input**: Requires typing "destroy" to confirm
2. **approval**: Manual approval for production
3. **backup**: Creates DynamoDB backups
4. **destroy-kubernetes**: Deletes K8s resources
5. **destroy-infrastructure**: Destroys Terraform resources
6. **cleanup-ecr**: Deletes ECR repositories
7. **cleanup-logs**: Deletes CloudWatch log groups
8. **final-verification**: Verifies all resources removed
9. **notify**: Sends destruction summary

**Usage**:
```bash
# Go to Actions tab in GitHub
# Select "Destroy Infrastructure"
# Click "Run workflow"
# Choose environment
# Type "destroy" in confirmation field
# Optionally skip approval (NOT recommended for production)
```

**⚠️ WARNING**: This is IRREVERSIBLE! Backups are created but review carefully.

---

### 3. Pull Request Checks (`pr-checks.yml`)

**Trigger**: Pull request to `main` branch

**Jobs**:
1. **terraform-check**: Format check, validation, TFLint
2. **kubernetes-check**: Manifest validation, Kubeval
3. **security-scan**: Trivy security scanning
4. **code-quality**: ESLint, secret scanning
5. **pr-comment**: Summary comment on PR

**Usage**: Automatically runs on PR creation/update

---

## Setup Instructions

### 1. Required GitHub Secrets

Navigate to: **Settings** → **Secrets and variables** → **Actions**

Add the following secrets:

```
AWS_ACCESS_KEY_ID          # From AWS SSO credentials
AWS_SECRET_ACCESS_KEY      # From AWS SSO credentials  
AWS_SESSION_TOKEN          # From AWS SSO credentials (expires!)
```

**Note**: AWS SSO credentials expire! You'll need to refresh them regularly using the `refresh-credentials.ps1` script and update the secrets.

### 2. Required GitHub Environments

Navigate to: **Settings** → **Environments**

Create environments:
- `dev`
- `staging`
- `production`
- `production-approval` (with required reviewers)
- `production-destruction` (with required reviewers)

### 3. Environment Variables (Optional)

In each environment, you can set:
```
AWS_REGION=eu-west-1
CLUSTER_NAME=innovatech-employee-lifecycle
```

---

## Workflow Diagrams

### Deploy Workflow
```
validate
   ↓
plan
   ↓
approval (production only)
   ↓
deploy-infrastructure
   ├→ deploy-kubernetes
   └→ build-images
        ↓
   post-deployment-tests
        ↓
      notify
```

### Destroy Workflow
```
validate-input
   ↓
approval (production only)
   ↓
backup
   ↓
destroy-kubernetes
   ↓
destroy-infrastructure
   ├→ cleanup-ecr
   └→ cleanup-logs
        ↓
   final-verification
        ↓
      notify
```

---

## Tips & Best Practices

### 1. AWS Credentials Refresh

AWS SSO credentials expire regularly. Refresh them:

```powershell
# Run this script
.\scripts\refresh-credentials.ps1

# Then update GitHub secrets:
# 1. Copy the three environment variables
# 2. Go to GitHub Settings → Secrets
# 3. Update all three secrets
```

### 2. Testing Before Production

Always test in `dev` first:
1. Deploy to `dev`
2. Test functionality
3. Review costs in AWS Cost Explorer
4. Destroy `dev` when satisfied
5. Deploy to `production`

### 3. Cost Management

- **Deploy to dev for testing**: Costs ~$12/day
- **Destroy when not in use**: Run destroy workflow
- **Use production sparingly**: Real costs accumulate

### 4. Monitoring Deployments

Check deployment progress:
```bash
# In Actions tab, click on running workflow
# View logs for each job
# Check for errors in real-time
```

### 5. Rollback Strategy

If deployment fails:
1. Check logs in Actions tab
2. Fix issue locally
3. Test with `terraform plan`
4. Push fix to trigger re-deployment

For critical failures:
1. Run destroy workflow
2. Fix issues
3. Re-deploy from scratch

---

## Troubleshooting

### Issue: Workflow fails with AWS credentials error

**Solution**: 
```powershell
# Refresh AWS credentials
.\scripts\refresh-credentials.ps1

# Update GitHub secrets (they expired!)
```

### Issue: Terraform state locked

**Solution**:
```bash
# SSH into your workspace or use AWS CloudShell
aws dynamodb delete-item \
  --table-name terraform-state-lock \
  --key '{"LockID":{"S":"innovatech-terraform-lock"}}'
```

### Issue: Kubernetes resources won't delete

**Solution**:
```bash
# Force delete stuck resources
kubectl delete namespace workspaces --grace-period=0 --force
kubectl delete pvc --all -n workspaces --grace-period=0 --force
```

### Issue: ECR images too large, slow push

**Solution**:
```bash
# Use Docker layer caching
# Or reduce image size in Dockerfile
```

### Issue: Deployment succeeds but services not accessible

**Solution**:
```bash
# Check LoadBalancer provisioning (takes 5-10 min)
kubectl get ingress -n hr-portal -w

# Check pod status
kubectl get pods -n hr-portal
kubectl logs -n hr-portal <pod-name>
```

---

## Cost Warnings

### Deploy Workflow
- Creates full infrastructure: ~$12-15/day
- ECR storage: ~$1/month per image
- Data transfer during deployment: ~$1

### Destroy Workflow
- **Free** (just API calls)
- But leaves some resources:
  - S3 buckets (if created)
  - CloudWatch logs (archived)
  - Route53 hosted zones (if created)

**Always verify destruction in AWS Console!**

---

## Advanced Usage

### Custom Terraform Variables

Edit workflow file to add:
```yaml
- name: Terraform Apply
  working-directory: ./terraform
  run: |
    terraform apply -auto-approve \
      -var="node_instance_types=[\"t3.large\"]" \
      -var="node_desired_size=5"
```

### Deploy to Custom Branch

Change trigger:
```yaml
on:
  push:
    branches:
      - main
      - develop  # Add custom branch
```

### Skip Certain Jobs

Add condition:
```yaml
jobs:
  build-images:
    if: github.event.inputs.skip_images != 'true'
```

---

## Monitoring & Alerts

### View Workflow Runs
1. Go to **Actions** tab
2. Select workflow
3. Click on run
4. View logs, timing, status

### Setup Notifications
1. Go to **Settings** → **Notifications**
2. Enable email notifications for:
   - Failed workflows
   - Successful deployments to production

### Cost Monitoring
Check AWS Cost Explorer after each deployment:
```
https://console.aws.amazon.com/cost-management/home
```

---

## Security Considerations

1. **Never commit AWS credentials** to code
2. **Use GitHub Environments** for protection rules
3. **Require approvals** for production
4. **Rotate credentials** regularly
5. **Review Trivy scan** results in PRs
6. **Enable branch protection** on `main`

---

## Support

For issues with workflows:
1. Check workflow logs in Actions tab
2. Review this documentation
3. Check AWS CloudWatch logs
4. Refer to main README.md

---

**Last Updated**: November 6, 2025  
**Version**: 1.0.0
