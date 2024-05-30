## GitHub Actions Workflow

### Infrastructure As Code

The GitHub Actions workflow automates the deployment of an EKS cluster along with the necessary infrastructure. It follows DevOps best practices by using Infrastructure as Code (IaC) with Terraform, ensuring reproducibility and consistency in infrastructure management. The workflow is split into two main jobs: `terraform` and `configure`.

## `Terraform` Job

The `terraform` job is responsible for provisioning the necessary infrastructure using Terraform. Below are the key steps involved:

1. **Setting Up Environment Variables:**
   - These variables are sourced from GitHub secrets to securely manage sensitive information.

   ```yaml
   env:
       AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
       AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
       BUCKET_TF_STATE: ${{ secrets.BUCKET_TF }}
       AWS_REGION: eu-central-1
       SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY}}



2. **Job Configuration:**
   - This configures the job to run on the latest Ubuntu runner and sets the working directory to ./terraform.

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


3. **Checkout Source Code:**
   - This step checks out the repository code.

    ```yaml
    - name: Checkout source code 
      uses: actions/checkout@v4


4. **Setup Terraform:**
   - Installs Terraform on the runner.

    ```yaml
    - name: Setup Terraform 
      uses: hashicorp/setup-terraform@v3


5. **Decode SSH Key:**
   - Decodes the SSH private key from secrets and sets the appropriate permissions.

    ```yaml
    - name: Decode SSH key
      run: |
        echo "${{ secrets.SSH_PRIVATE_KEY }}" > private_key.pem
        chmod 400 private_key.pem


6. **Initialize Terraform, Validate and Plan:**
   - Initializes Terraform, using a remote backend for storing the state file in an S3 bucket.
     Validates the Terraform configuration files for syntax errors and other issues.
     Creates an execution plan to preview the changes that Terraform will apply.

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


7. **Apply Terraform Configuration:**
    - Applies the Terraform configuration to create the infrastructure.

    ```yaml
    - name: Terraform Apply
      id: apply
      run: terraform apply -auto-approve -input=false -parallelism=1 planfile


8. **Get Host Public IP:**
   - Retrieves the public IP address of the host instance created by Terraform.

    ```yaml
    - name: Get host public IP
      id: get_ip
      run: |
        echo "host_ip=$(terraform output -raw host_public_ip)" >> $GITHUB_OUTPUT         


## `Configure` Job
The configure job sets up the host instance and configures the EKS cluster. It depends on the terraform job.

1. **Job Configuration:**
   - Job starts only after successful complete `terraform` job.

    ```yaml
    jobs:
      configure:
        name: "Configure Host"
        runs-on: ubuntu-latest
        needs: terraform
        defaults:
          run:
            shell: bash


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
    
    ```bash
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

1. **Source Code Checkout:**  
   - Utilizes GitHub Actions to fetch the latest version of the frontend source code.

2. **Dependency Installation, Testing and Building:**  
   - Sets up the required Node.js environment.
   - Installs project dependencies.
   - Executes automated tests to validate the frontend code.
   - Builds the frontend application to prepare it for deployment.

    ```yaml
    strategy:
      matrix:
        node-version: [18.x]
    steps:
      - name: Check-out git repository  
        uses: actions/checkout@v4

      - name: USE NODEJS ${{ matrix.node-version }}
        uses: actions/setup-node@v4

      - name: Install project dependencies 
        working-directory: ./app/frontend
        run: |
          npm install
          npm test
        env:
          CI: true 

      - name: Build
        run: npm run build
        working-directory: ./app/frontend
   

3. **Static Code Analysis with SonarCloud:**  
   - Performs static code analysis using SonarCloud to identify potential code quality issues and security vulnerabilities.
    
    ```yaml
    - name: SonarCloud Scan
        uses: SonarSource/sonarcloud-github-action@master
        env: 
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        with:
          projectBaseDir: app/frontend
          args: >
            -Dsonar.organization=${{ secrets.SONAR_ORGANIZATION }}
            -Dsonar.projectKey=${{ secrets.SONAR_PROJECT_KEY }}
            -Dsonar.login=${{ secrets.SONAR_TOKEN }}

4. **Dockerization:**  
   - Builds a Docker image of the frontend application.
   - Tags the Docker image with the appropriate version.
   - Pushes the Docker image to Docker Hub for distribution.
    
    ```yaml
    - name: Build Docker image
        run: |
          docker build -t cvapp-web:latest .    

      - name: Tag Docker image
        run: |
          docker tag cvapp-web:latest michalziaja/cvapp-web:${{ github.run_number }}

      - name: Log in to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Push image to Docker Hub
        run: |
          docker push michalziaja/cvapp-web:${{ github.run_number }}


5. **Image Scanning with Trivy:**  
   - Scans the Docker image for known vulnerabilities using Trivy.
    
    ```yaml
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: 'docker.io/michalziaja/cvapp-web:${{ github.run_number }}'
        format: 'sarif'
        output: 'trivy-results.sarif'
        severity: 'CRITICAL,HIGH'


#### Backend Pipeline

The backend pipeline focuses on the backend application, ensuring its reliability and security:

1. **Source Code Checkout:**  
   - Retrieves the latest version of the backend source code from the repository.

2. **Dependency Installation:**  
   - Sets up the Python environment.
   - Installs backend dependencies required for the application.

    ```yaml
    strategy:
      matrix:
        python-version: ["3.10"]
    steps:
      - name: Check-out git repository  
        uses: actions/checkout@v4
      
      - name: Set up Python ${{ matrix.python-version }}
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
      
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt


3. **Static Code Analysis with SonarCloud:**  
   - Performs static code analysis using SonarCloud to identify potential code quality issues and security vulnerabilities.

    ```yaml
    - name: SonarCloud Scan
        uses: SonarSource/sonarcloud-github-action@master
        env: 
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        with:
          projectBaseDir: app/backend
          args: >
            -Dsonar.organization=${{ secrets.SONAR_ORGANIZATION }}
            -Dsonar.projectKey=${{ secrets.SONAR_PROJECT_KEY }}
            -Dsonar.login=${{ secrets.SONAR_TOKEN }}  


4. **Dockerization:**  
   - Builds a Docker image of the frontend application.
   - Tags the Docker image with the appropriate version.
   - Pushes the Docker image to Docker Hub for distribution.
    
    ```yaml
    - name: Build Docker image
        run: |
          docker build -t cvapp-api:latest .    

      - name: Tag Docker image
        run: |
          docker tag cvapp-api:latest michalziaja/cvapp-api:${{ github.run_number }}

      - name: Log in to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Push image to Docker Hub
        run: |
          docker push michalziaja/cvapp-api:${{ github.run_number }}

5. **Image Scanning with Trivy:**  
   - Scans the Docker image for known vulnerabilities using Trivy.

    ```yaml
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: 'docker.io/michalziaja/cvapp-api:${{ github.run_number }}'
        format: 'sarif'
        output: 'trivy-results.sarif'
        severity: 'CRITICAL,HIGH'


#### Combined Operations

1. **Update Kubernetes Deployment Files:**  
   - Start when Fronend and Backend pipelines are complete.
   - Modifies Kubernetes deployment files to use the newly built Docker images for both frontend and backend components.
   - Commits the changes back to the repository for version control.

    ```yaml
    - name: Update deployment files
        run: |
          git config --global user.email "michalziaja88@gmail.com"
          git config --global user.name "michalziaja"
          sed -i 's|image: michalziaja/cvapp-api[^ ]*|image: michalziaja/cvapp-api:${{ github.run_number }}|' kubernetes/api.yaml
          sed -i 's|image: michalziaja/cvapp-web[^ ]*|image: michalziaja/cvapp-web:${{ github.run_number }}|' kubernetes/web.yaml
          git add kubernetes/api.yaml
          git add kubernetes/web.yaml
          git commit -m "Update images to tag ${{ github.run_number }}"
          git push origin main


2. **Kubernetes Manifest Scan:**  
   - Scans the Kubernetes manifest files for potential security vulnerabilities and configuration issues using Snyk.

    ```yaml
    - uses: actions/checkout@v4
      - name: Run Snyk to check Kubernetes manifest file for issues
        uses: snyk/actions/iac@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          file: kubernetes/
          args: --severity-threshold=high

