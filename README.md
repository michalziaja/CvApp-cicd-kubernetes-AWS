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

These variables are sourced from GitHub secrets to securely manage sensitive information.

2. **Job Configuration:**
    
    ```yaml
    jobs:
      terraform:
        name: "Terraform"
        runs-on: ubuntu-latest
        outputs: 
          host_ip: ${{ steps.get_ip.outputs.host_ip }}
        defaults:
          run:
            shell: bash
            working-directory: ./terraform

This configures the job to run on the latest Ubuntu runner and sets the working directory to ./terraform.

3. **Checkout Source Code:**
    
    ```yaml
    - name: Checkout source code 
      uses: actions/checkout@v4

This step checks out the repository code.

4. **Setup Terraform:**
    
    ```yaml
    - name: Setup Terraform 
      uses: hashicorp/setup-terraform@v3

Installs Terraform on the runner.

5. **Decode SSH Key:**

    ```yaml
    - name: Decode SSH key
      run: |
        echo "${{ secrets.SSH_PRIVATE_KEY }}" > private_key.pem
        chmod 400 private_key.pem

Decodes the SSH private key from secrets and sets the appropriate permissions.

6. **Initialize Terraform, Validate and Plan:**

    ```yaml
    - name: Terraform Init
      id: init
      run: terraform init -backend-config "bucket=$BUCKET_TF_STATE"
      
    - name: Terraform Validate
      id: validate
      run: terraform validate

    - name: Terraform Plan
      id: plan
      run: terraform plan -no-color -input=false -out planfile
      continue-on-error: true 

Initializes Terraform, using a remote backend for storing the state file in an S3 bucket.
Validates the Terraform configuration files for syntax errors and other issues.
Creates an execution plan to preview the changes that Terraform will apply.

7. **Apply Terraform Configuration:**
    
    ```yaml
    - name: Terraform Apply
      id: apply
      run: terraform apply -auto-approve -input=false -parallelism=1 planfile

Applies the Terraform configuration to create the infrastructure.

8. **Get Host Public IP:**
    
    ```yaml
    - name: Get host public IP
      id: get_ip
      run: |
        echo "host_ip=$(terraform output -raw host_public_ip)" >> $GITHUB_OUTPUT         

Retrieves the public IP address of the host instance created by Terraform.