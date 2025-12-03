# CI/CD Pipeline for Zero Trust Architecture

This project uses GitHub Actions for Continuous Integration and Deployment. The pipeline has been updated to support the Zero Trust architecture, specifically handling the integration between Terraform outputs (Cognito IDs, Security Groups) and Kubernetes manifests.

## Workflow: `deploy.yml`

The deployment pipeline consists of the following stages:

1.  **Validate**: Checks Terraform formatting and validates Kubernetes manifests using `kubeconform`.
2.  **Plan**: Runs `terraform plan` and uploads the plan as an artifact.
3.  **Deploy Infrastructure**:
    *   Runs `terraform apply`.
    *   **Crucial Step**: Exports Terraform outputs to `outputs.json` and uploads it as an artifact. This file contains the Cognito User Pool IDs, Client IDs, and Security Group IDs needed for the application.
4.  **Build Images**: Builds Docker images for HR Portal (Frontend/Backend) and pushes them to ECR.
5.  **Deploy Kubernetes**:
    *   Downloads the `outputs.json` artifact.
    *   **Crucial Step**: Runs `scripts/update-k8s-manifests.ps1` to inject the Terraform outputs into `hr-portal.yaml` and `workspaces.yaml`.
    *   Applies the updated manifests to the EKS cluster.
    *   Restarts deployments to ensure new images are pulled.
6.  **Post-Deployment Tests**:
    *   Verifies Pod health.
    *   Checks Internal ALB status (Note: External access checks are disabled as the ALB is now private).

## Key Files

*   `.github/workflows/deploy.yml`: The main workflow file.
*   `scripts/update-k8s-manifests.ps1`: PowerShell script that bridges Terraform and Kubernetes. It can now read from a JSON file for CI/CD usage.

## Setup Requirements

Ensure your GitHub Repository Secrets are configured:
*   `DIRECTORY_ADMIN_PASSWORD`: Password for the Directory Service (if used).
*   AWS OIDC Role: The workflow uses `arn:aws:iam::920120424621:role/githubrepo`. Ensure this role exists and trusts your GitHub repository.

## Triggering the Pipeline

The pipeline runs automatically on pushes to `main` that affect relevant files. You can also trigger it manually via the "Actions" tab in GitHub.
