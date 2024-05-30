## GitHub Actions Workflow

### Overview

The GitHub Actions workflow automates the deployment of an EKS cluster along with the necessary infrastructure. It follows DevOps best practices by using Infrastructure as Code (IaC) with Terraform, ensuring reproducibility and consistency in infrastructure management. The workflow is split into two main jobs: `terraform` and `configure`.

### `terraform` Job

The `terraform` job is responsible for provisioning the necessary infrastructure using Terraform. Below are the key steps involved:

1. **Setting Up Environment Variables:**

   ```yaml
   env:
       AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
       AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
       BUCKET_TF_STATE: ${{ secrets.BUCKET_TF }}
       AWS_REGION: eu-central-1
       SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY}}
