# IAM Role OIDC Setup voor GitHub Actions

## Probleem

De workflow loopt vast bij "Assuming role with OIDC". Dit betekent dat de IAM role trust policy niet correct is voor GitHub Actions.

## Oplossing: Configureer IAM Role Trust Policy

### Stap 1: Check OIDC Provider

Verifieer of de OIDC provider bestaat:

```bash
aws iam list-open-id-connect-providers
```

Als de provider er **NIET** is, maak hem aan:

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### Stap 2: Update Role Trust Policy

De `githubrepo` role heeft deze trust policy nodig:

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

**Opslaan als `trust-policy.json` en toepassen:**

```bash
aws iam update-assume-role-policy \
  --role-name githubrepo \
  --policy-document file://trust-policy.json
```

### Stap 3: Verifieer Trust Policy

```bash
aws iam get-role --role-name githubrepo --query 'Role.AssumeRolePolicyDocument'
```

---

## Alternatief: Gebruik Access Keys (Tijdelijk)

Als OIDC setup tijd kost, kun je tijdelijk access keys gebruiken:

### 1. Refresh AWS Credentials

```powershell
.\scripts\refresh-credentials.ps1
```

### 2. Voeg GitHub Secrets toe

Ga naar: **GitHub repo → Settings → Secrets and variables → Actions**

Voeg toe:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`

### 3. Update Workflow (Tijdelijk)

In `.github/workflows/deploy.yml`, vervang:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::920120424621:role/githubrepo
    aws-region: ${{ env.AWS_REGION }}
```

Met:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-session-token: ${{ secrets.AWS_SESSION_TOKEN }}
    aws-region: ${{ env.AWS_REGION }}
```

---

## Troubleshooting

### Error: "Not authorized to perform sts:AssumeRoleWithWebIdentity"

**Oorzaak**: Trust policy is niet correct of OIDC provider bestaat niet.

**Fix**: Volg Stap 1 en 2 hierboven.

### Error: "No OpenIDConnect provider found"

**Oorzaak**: OIDC provider bestaat niet in AWS account.

**Fix**: Run Stap 1 command om provider te maken.

### Error: "Token audience validation failed"

**Oorzaak**: Audience in trust policy is verkeerd.

**Fix**: Zorg dat `aud` is `sts.amazonaws.com` (niet `sigstore` of iets anders).

### Error: "Subject claim validation failed"

**Oorzaak**: Repository naam in trust policy komt niet overeen.

**Fix**: Check dat `sub` is `repo:i546927MehdiCetinkaya/casestudy3:*` (met wildcard).

---

## Verificatie Commands

```bash
# Check OIDC provider
aws iam list-open-id-connect-providers

# Check role trust policy
aws iam get-role --role-name githubrepo

# Check role permissions
aws iam list-attached-role-policies --role-name githubrepo

# Test locally (als je OIDC wil testen)
# Note: OIDC werkt alleen vanuit GitHub Actions, niet lokaal
```

---

## Recommended: Fix OIDC (Beste oplossing)

OIDC is veiliger en heeft geen expiring credentials. Volg de stappen hierboven om het te fixen.

## Quick Fix: Use Access Keys (Tijdelijke workaround)

Als je snel wil deployen en OIDC later wil fixen, gebruik dan access keys zoals beschreven in "Alternatief" sectie.

---

**Kies een optie en deploy!** 🚀
