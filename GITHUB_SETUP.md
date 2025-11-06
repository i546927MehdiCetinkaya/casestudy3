# GitHub Actions met IAM Role - Setup Gids

## ✅ Wat is gedaan

De GitHub Actions workflows gebruiken nu **IAM Role** `githubrepo` in plaats van secrets!

### Voordelen:
- ✅ **Geen secrets** meer nodig in GitHub
- ✅ **Geen expiring credentials** - IAM role werkt altijd
- ✅ **Veiliger** - OIDC authentication met GitHub
- ✅ **Makkelijker** - Geen credential refresh nodig

---

## 🔧 IAM Role Setup (al gedaan!)

Je hebt al een IAM role: `arn:aws:iam::920120424621:role/githubrepo`

Deze role moet:
1. **Trust Policy** hebben voor GitHub Actions OIDC
2. **Permissions** hebben voor AWS services

---

## 📋 Checklist voor Deployment

### 1. Verifieer IAM Role Trust Policy

De role moet GitHub Actions toestaan:

```bash
aws iam get-role --role-name githubrepo --query 'Role.AssumeRolePolicyDocument'
```

Expected trust policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::920120424621:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:i546927MehdiCetinkaya/casestudy3:*"
        }
      }
    }
  ]
}
```

### 2. Verifieer IAM Role Permissions

De role heeft deze permissions nodig:

```bash
aws iam list-attached-role-policies --role-name githubrepo
```

Required policies:
- ✅ EC2/VPC management (create VPC, subnets, IGW, NAT, etc.)
- ✅ EKS management (create cluster, node groups)
- ✅ ECR (create repositories, push images)
- ✅ DynamoDB (create tables)
- ✅ CloudWatch (create log groups)
- ✅ IAM (create roles for IRSA)

**Check permissions:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:*",
        "ec2:*",
        "ecr:*",
        "dynamodb:*",
        "logs:*",
        "iam:CreateRole",
        "iam:PutRolePolicy",
        "iam:AttachRolePolicy",
        "iam:GetRole",
        "iam:PassRole",
        "iam:CreateOpenIDConnectProvider",
        "iam:GetOpenIDConnectProvider",
        "iam:TagOpenIDConnectProvider"
      ],
      "Resource": "*"
    }
  ]
}
```

### 3. Setup GitHub OIDC Provider (als nog niet gedaan)

Check of OIDC provider bestaat:
```bash
aws iam list-open-id-connect-providers
```

Als hij er niet is, maak hem aan:
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### 4. Test de Workflows

#### Deploy:
```bash
# Push code naar main branch of:
# Go to Actions → Deploy Infrastructure → Run workflow
```

#### Destroy:
```bash
# Go to Actions → Destroy Infrastructure → Run workflow
# Type "destroy" to confirm
```

---

## 🚀 Deployment Stappen

### Lokaal Testen (optioneel):
```powershell
# Format terraform
terraform fmt -recursive terraform/

# Validate
cd terraform
terraform init
terraform validate
cd ..

# Commit and push
git add .
git commit -m "Setup IAM role authentication"
git push
```

### Via GitHub Actions:
1. Push code naar GitHub
2. Go to **Actions** tab
3. Select **Deploy Infrastructure**
4. Click **Run workflow**
5. Wait for completion (~15-20 min)

---

## 🔍 Troubleshooting

### Error: "AssumeRole failed"
**Oorzaak**: Trust policy is niet correct

**Fix**:
```bash
# Check trust policy
aws iam get-role --role-name githubrepo

# Update trust policy if needed (zie boven voor template)
aws iam update-assume-role-policy \
  --role-name githubrepo \
  --policy-document file://trust-policy.json
```

### Error: "Access Denied" tijdens deployment
**Oorzaak**: Role heeft niet genoeg permissions

**Fix**:
```bash
# Attach more policies
aws iam attach-role-policy \
  --role-name githubrepo \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess

aws iam attach-role-policy \
  --role-name githubrepo \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
```

### Error: "OIDC provider not found"
**Oorzaak**: GitHub OIDC provider bestaat niet

**Fix**: Run setup command in stap 3 hierboven

---

## 📊 Kosten

Met IAM role: **Gratis** (geen extra kosten voor authentication)
Infrastructure costs: ~$12-15/dag tijdens deployment

**Tip**: Destroy infrastructure wanneer je het niet gebruikt!

---

## 🎯 Quick Commands

```powershell
# Format terraform
terraform fmt -recursive terraform/

# Check workflows syntax
cat .github\workflows\deploy.yml
cat .github\workflows\destroy.yml

# Check IAM role
aws iam get-role --role-name githubrepo

# List OIDC providers
aws iam list-open-id-connect-providers

# Test AWS connection locally
aws sts get-caller-identity
```

---

## 📚 Meer Info

- [GitHub OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [AWS IAM Roles](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

**Klaar om te deployen!** 🚀
