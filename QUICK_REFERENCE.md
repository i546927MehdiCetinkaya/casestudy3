# Quick Reference Guide
## Employee Lifecycle Automation System

### Common Commands

#### AWS Setup
```powershell
# Configure AWS CLI
aws configure

# Verify credentials
aws sts get-caller-identity

# Set default region
$env:AWS_DEFAULT_REGION="eu-west-1"
```

#### Terraform
```powershell
cd terraform

# Initialize
terraform init

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Destroy (CAREFUL!)
terraform destroy

# Show outputs
terraform output
```

#### kubectl Configuration
```powershell
# Update kubeconfig
aws eks update-kubeconfig --region eu-west-1 --name innovatech-employee-lifecycle

# Verify connection
kubectl cluster-info
kubectl get nodes

# View contexts
kubectl config get-contexts
```

#### Kubernetes Operations
```powershell
# Get all resources
kubectl get all -n hr-portal
kubectl get all -n workspaces

# View pods
kubectl get pods -n hr-portal -o wide
kubectl get pods -n workspaces -o wide

# View logs
kubectl logs -n hr-portal -l app=hr-portal-backend --tail=50
kubectl logs -n hr-portal -l app=hr-portal-backend -f

# Describe resources
kubectl describe pod <pod-name> -n hr-portal
kubectl describe ingress -n hr-portal

# Execute commands in pod
kubectl exec -it <pod-name> -n hr-portal -- /bin/sh

# Port forwarding (for local testing)
kubectl port-forward -n hr-portal svc/hr-portal-backend 3000:80
```

#### Docker & ECR
```powershell
# Get account ID
$accountId = aws sts get-caller-identity --query Account --output text

# ECR login
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin $accountId.dkr.ecr.eu-west-1.amazonaws.com

# Build image
docker build -t hr-portal-backend .

# Tag image
docker tag hr-portal-backend:latest $accountId.dkr.ecr.eu-west-1.amazonaws.com/hr-portal-backend:latest

# Push image
docker push $accountId.dkr.ecr.eu-west-1.amazonaws.com/hr-portal-backend:latest

# List images
aws ecr list-images --repository-name hr-portal-backend
```

#### API Testing
```powershell
# Health check
curl https://hr.innovatech.example.com/api/health

# Get employees
curl https://hr.innovatech.example.com/api/employees

# Create employee
$body = @{
    firstName = "John"
    lastName = "Doe"
    email = "john.doe@innovatech.com"
    role = "developer"
    department = "Engineering"
} | ConvertTo-Json

curl -X POST https://hr.innovatech.example.com/api/employees `
  -H "Content-Type: application/json" `
  -d $body

# Update employee
$body = @{
    department = "Data Science"
} | ConvertTo-Json

curl -X PUT https://hr.innovatech.example.com/api/employees/<id> `
  -H "Content-Type: application/json" `
  -d $body

# Delete employee (offboard)
curl -X DELETE https://hr.innovatech.example.com/api/employees/<id>
```

#### DynamoDB
```powershell
# List tables
aws dynamodb list-tables

# Describe table
aws dynamodb describe-table --table-name innovatech-employees

# Get item
aws dynamodb get-item `
  --table-name innovatech-employees `
  --key '{\"employeeId\":{\"S\":\"<id>\"}}'

# Scan table (list all)
aws dynamodb scan --table-name innovatech-employees

# Query by email
aws dynamodb query `
  --table-name innovatech-employees `
  --index-name EmailIndex `
  --key-condition-expression "email = :email" `
  --expression-attribute-values '{\":email\":{\"S\":\"john.doe@innovatech.com\"}}'
```

#### Monitoring & Debugging
```powershell
# CloudWatch logs
aws logs tail /aws/eks/innovatech-employee-lifecycle/cluster --follow

# VPC Flow Logs
aws logs tail /aws/vpc/innovatech-employee-lifecycle --follow

# Get pod metrics
kubectl top pods -n hr-portal
kubectl top nodes

# View events
kubectl get events -n hr-portal --sort-by='.lastTimestamp'

# Check NetworkPolicies
kubectl get networkpolicies -n hr-portal
kubectl describe networkpolicy <name> -n hr-portal
```

### Troubleshooting

#### Pod won't start
```powershell
# Check pod status
kubectl describe pod <pod-name> -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace>

# Check image pull
kubectl get events -n <namespace> | Select-String "Failed"

# Verify ECR permissions
aws ecr get-login-password --region eu-west-1
```

#### Cannot access application
```powershell
# Check ingress
kubectl get ingress -n hr-portal
kubectl describe ingress -n hr-portal

# Check service
kubectl get svc -n hr-portal
kubectl describe svc hr-portal-backend -n hr-portal

# Check ALB
aws elbv2 describe-load-balancers

# Test from inside cluster
kubectl run test-pod --image=busybox --rm -it -- wget -O- http://hr-portal-backend.hr-portal
```

#### NetworkPolicy issues
```powershell
# List NetworkPolicies
kubectl get networkpolicies --all-namespaces

# Test connectivity
kubectl run test-pod --image=busybox -n default --rm -it -- wget -O- http://hr-portal-backend.hr-portal

# Check DNS
kubectl run test-pod --image=busybox -n default --rm -it -- nslookup kubernetes.default
```

#### DynamoDB access issues
```powershell
# Check IRSA role
kubectl describe sa hr-portal-backend -n hr-portal

# Verify IAM role
aws iam get-role --role-name innovatech-employee-lifecycle-hr-portal-role

# Check VPC endpoint
aws ec2 describe-vpc-endpoints --filters Name=service-name,Values=com.amazonaws.eu-west-1.dynamodb
```

### Useful Aliases (Add to PowerShell Profile)
```powershell
# Edit profile: notepad $PROFILE

# Aliases
function k { kubectl $args }
function kgp { kubectl get pods $args }
function kgpa { kubectl get pods --all-namespaces $args }
function kgd { kubectl get deployments $args }
function kgs { kubectl get svc $args }
function kgi { kubectl get ingress $args }
function kdp { kubectl describe pod $args }
function kl { kubectl logs $args }
function klf { kubectl logs -f $args }
function kex { kubectl exec -it $args }

# Usage: kgp -n hr-portal
```

### Environment Variables
```powershell
# Set common variables
$env:AWS_REGION="eu-west-1"
$env:CLUSTER_NAME="innovatech-employee-lifecycle"
$env:ACCOUNT_ID=(aws sts get-caller-identity --query Account --output text)
$env:ECR_REGISTRY="$env:ACCOUNT_ID.dkr.ecr.$env:AWS_REGION.amazonaws.com"

# Use in commands
docker push $env:ECR_REGISTRY/hr-portal-backend:latest
```

### Important URLs & Resources

#### AWS Console
- EKS Cluster: https://console.aws.amazon.com/eks/home?region=eu-west-1
- DynamoDB: https://console.aws.amazon.com/dynamodbv2/home?region=eu-west-1
- CloudWatch: https://console.aws.amazon.com/cloudwatch/home?region=eu-west-1
- VPC: https://console.aws.amazon.com/vpc/home?region=eu-west-1
- ECR: https://console.aws.amazon.com/ecr/repositories?region=eu-west-1

#### Application URLs (Update with actual domains)
- HR Portal: https://hr.innovatech.example.com
- Workspace (example): https://john-doe.workspaces.innovatech.example.com

#### Documentation
- AWS EKS: https://docs.aws.amazon.com/eks/
- Kubernetes: https://kubernetes.io/docs/
- Terraform: https://www.terraform.io/docs/
- DynamoDB: https://docs.aws.amazon.com/dynamodb/

### Quick Deployment
```powershell
# One-line deployment (after AWS setup)
.\scripts\deploy.ps1
```

### Quick Cleanup
```powershell
# Delete Kubernetes resources
kubectl delete -f kubernetes/workspaces.yaml
kubectl delete -f kubernetes/hr-portal.yaml
kubectl delete -f kubernetes/network-policies.yaml
kubectl delete -f kubernetes/rbac.yaml

# Destroy infrastructure
cd terraform
terraform destroy -auto-approve
```

### Security Checklist
- [ ] AWS credentials configured securely
- [ ] Never commit secrets to Git
- [ ] Use strong passwords for workspaces
- [ ] Rotate credentials regularly
- [ ] Enable MFA on AWS accounts
- [ ] Review IAM policies regularly
- [ ] Monitor CloudWatch logs for anomalies
- [ ] Keep EKS and nodes updated
- [ ] Scan container images for vulnerabilities

### Support & Resources
- GitHub Repository: https://github.com/i546927MehdiCetinkaya/casestudy3
- Issue Tracker: https://github.com/i546927MehdiCetinkaya/casestudy3/issues
- README: See README.md
- Architecture: See docs/ARCHITECTURE.md
- Testing: See tests/TEST_PLAN.md

---

**Quick Reference Version**: 1.0.0  
**Last Updated**: November 6, 2025