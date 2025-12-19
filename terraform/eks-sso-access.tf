# Add SSO role access to EKS cluster via aws-auth ConfigMap
# This is a temporary fix until we can migrate to access entries

data "aws_caller_identity" "current" {}

locals {
  sso_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AWSReservedSSO_fictisb_IsbUsersPS_2f9b7e07b8441d9f"
}

# Use null_resource to update aws-auth via kubectl
resource "null_resource" "update_aws_auth" {
  triggers = {
    cluster_name = module.eks.cluster_name
    sso_role_arn = local.sso_role_arn
  }

  provisioner "local-exec" {
    command     = "$env:AWS_DEFAULT_REGION='${var.aws_region}'; aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}; kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth-backup.yaml 2>$null; @'\napiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: aws-auth\n  namespace: kube-system\ndata:\n  mapRoles: |\n    - rolearn: ${module.eks.node_role_arn}\n      username: system:node:{{EC2PrivateDNSName}}\n      groups:\n        - system:bootstrappers\n        - system:nodes\n    - rolearn: ${local.sso_role_arn}\n      username: sso-admin\n      groups:\n        - system:masters\n    - rolearn: arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/innovatech-employee-lifecycle-admin-role\n      username: admin\n      groups:\n        - system:masters\n'@ | kubectl apply -f -"
    interpreter = ["powershell", "-Command"]
  }

  depends_on = [module.eks]
}
