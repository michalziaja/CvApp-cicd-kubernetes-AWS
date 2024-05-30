## GitHub Actions Workflow

### Overview

The GitHub Actions workflow automates the deployment of an EKS cluster along with the necessary infrastructure. It follows DevOps best practices by using Infrastructure as Code (IaC) with Terraform, ensuring reproducibility and consistency in infrastructure management. The workflow is split into two main jobs: `terraform` and `configure`.

## `Terraform` Job

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

## `Configure` Job
The configure job sets up the host instance and configures the EKS cluster. It depends on the terraform job.

1. **Job Configuration:**
    
    ```yaml
    jobs:
      configure:
        name: "Configure Host"
        runs-on: ubuntu-latest
        needs: terraform
        defaults:
          run:
            shell: bash

Job starts only after successful complete `terraform` job.

2. **AWS CLI Setup:**
   - Configures the AWS CLI on the host instance with necessary credentials, using `GITHUB_OUTPUT` host_ip from previous job.

    ```yaml
    - name: AWS CLI
      id: aws_cli
      run: |
        echo "${{ secrets.SSH_PRIVATE_KEY }}" > private_key.pem && \
        chmod 400 private_key.pem
        ssh -i private_key.pem -o StrictHostKeyChecking=no ubuntu@${{ needs.terraform.outputs.host_ip }} "\
        aws configure set aws_access_key_id ${{ secrets.AWS_ACCESS_KEY_ID }} && \
        aws configure set aws_secret_access_key ${{ secrets.AWS_SECRET_ACCESS_KEY }} && \
        aws configure set region eu-central-1 && \
        aws configure list"



3. **Install Kubectl & Eksctl:**
    
    ```yaml
    - name: Kubectl & eksctl
      uses: appleboy/ssh-action@v1.0.3
      id: ec2_configure  
      with:
      host: ${{ needs.terraform.outputs.host_ip }}
      username: ubuntu
      key: ${{ secrets.SSH_PRIVATE_KEY}}
      port: 22
      script: |
        sudo chmod +x install.sh
        ./install.sh

4. **Install Helm, ALB Controller, ArgoCD, Prometheus, Grafana:**
   - Connects to the EKS cluster, associates IAM OIDC provider, and installs Helm, ALB controller, ArgoCD, Prometheus and Grafana using the install2.sh script. 
    
    ```yaml
    - name: Install Helm/Alb/ArgoCD
      uses: appleboy/ssh-action@v1.0.3
      id: eks_configure  
      with:
        host: ${{ needs.terraform.outputs.host_ip }}
        username: ubuntu
        key: ${{ secrets.SSH_PRIVATE_KEY}}
        port: 22
        script: |
          echo 'Connect to cluster'
          aws eks update-kubeconfig --region eu-central-1 --name cvapp-eks
          eksctl utils associate-iam-oidc-provider --region=eu-central-1 --cluster=cvapp-eks --approve     
          echo 'Run Install2'
          sudo chmod +x install2.sh
          ./install2.sh

- Services for ArgoCD, Grafana and Prometheus are patched to be exposed by Classic LoadBalancers.
    
    kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
    kubectl patch svc prometheus-kube-prometheus-prometheus -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
    kubectl patch svc grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'


5. **Output Important Information:**
    
    ```yaml
    echo "########## OUTPUTS ##########"
    echo "########## HOST IP ##########"
    wget -qO- ifconfig.me; echo
    echo "########## ArgoCD Server ##########"
    echo $ARGOCD_SERVER
    echo "########## ArgoCD Pass ##########"
    echo $ARGOCD_PWD
    echo "########## Grafana Server ##########"
    echo $GRAFANA_SERVER
    echo "########## Grafana Pass ##########"
    echo $GRAFANA_PWD
    echo "########## Prometheus Server ##########"
    echo $PROMETHEUS_SERVER



### Continuous Integration (CI) Pipelines

The CI pipelines automate the testing, building, and deployment processes for both the frontend and backend components of the project. They ensure code quality, security, and efficient delivery to the target environment.

#### Frontend Pipeline

The frontend pipeline focuses on the frontend application, ensuring its stability and security:

1. **Source Code Checkout:**  
   - Utilizes GitHub Actions to fetch the latest version of the frontend source code.

2. **Dependency Installation and Testing:**  
   - Sets up the required Node.js environment.
   - Installs project dependencies.
   - Executes automated tests to validate the frontend code.

3. **Building:**  
   - Builds the frontend application to prepare it for deployment.

4. **Static Code Analysis with SonarCloud:**  
   - Performs static code analysis using SonarCloud to identify potential code quality issues and security vulnerabilities.

5. **Dockerization:**  
   - Builds a Docker image of the frontend application.

6. **Image Scanning with Trivy:**  
   - Scans the Docker image for known vulnerabilities using Trivy.

7. **Image Tagging and Pushing:**  
   - Tags the Docker image with the appropriate version.
   - Pushes the Docker image to Docker Hub for distribution.

#### Backend Pipeline

The backend pipeline focuses on the backend application, ensuring its reliability and security:

1. **Source Code Checkout:**  
   - Retrieves the latest version of the backend source code from the repository.

2. **Dependency Installation:**  
   - Sets up the Python environment.
   - Installs backend dependencies required for the application.

3. **Static Code Analysis with SonarCloud:**  
   - Conducts static code analysis using SonarCloud to detect potential code issues and vulnerabilities.

4. **Dockerization:**  
   - Builds a Docker image of the backend application.

5. **Image Scanning with Trivy:**  
   - Scans the Docker image for vulnerabilities using Trivy.

6. **Image Tagging and Pushing:**  
   - Tags the Docker image with the appropriate version.
   - Pushes the Docker image to Docker Hub for further deployment.

#### Combined Operations

1. **Update Kubernetes Deployment Files:**  
   - Modifies Kubernetes deployment files to use the newly built Docker images for both frontend and backend components.
   - Commits the changes back to the repository for version control.

2. **Kubernetes Manifest Scan:**  
   - Scans the Kubernetes manifest files for potential security vulnerabilities and configuration issues using Snyk.

These CI pipelines provide a streamlined approach to ensure code quality, security, and efficient deployment of both frontend and backend components of the project.
