Overview
The GitHub Actions workflow automates the deployment of an EKS cluster along with the necessary infrastructure. It follows DevOps best practices by using Infrastructure as Code (IaC) with Terraform, ensuring reproducibility and consistency in infrastructure management. The workflow is split into two main jobs: terraform and configure.

terraform Job
The terraform job is responsible for provisioning the necessary infrastructure using Terraform. Below are the key steps involved:

Setting Up Environment Variables:

yaml
Skopiuj kod
env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    BUCKET_TF_STATE: ${{ secrets.BUCKET_TF }}
    AWS_REGION: eu-central-1
    SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY}}
These variables are sourced from GitHub secrets to securely manage sensitive information.

Job Configuration:

yaml
Skopiuj kod
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

Checkout Source Code:

yaml
Skopiuj kod
- name: Checkout source code 
  uses: actions/checkout@v4
This step checks out the repository code.

Setup Terraform:

yaml
Skopiuj kod
- name: Setup Terraform 
  uses: hashicorp/setup-terraform@v3
Installs Terraform on the runner.

Decode SSH Key:

yaml
Skopiuj kod
- name: Decode SSH key
  run: |
    echo "${{ secrets.SSH_PRIVATE_KEY }}" > private_key.pem
    chmod 400 private_key.pem
Decodes the SSH private key from secrets and sets the appropriate permissions.

Initialize Terraform:

yaml
Skopiuj kod
- name: Terraform Init
  id: init
  run: terraform init -backend-config "bucket=$BUCKET_TF_STATE"
Initializes Terraform, using a remote backend for storing the state file in an S3 bucket.

Validate Terraform Configuration:

yaml
Skopiuj kod
- name: Terraform Validate
  id: validate
  run: terraform validate
Validates the Terraform configuration files for syntax errors and other issues.

Terraform Plan:

yaml
Skopiuj kod
- name: Terraform Plan
  id: plan
  run: terraform plan -no-color -input=false -out planfile
  continue-on-error: true 
Creates an execution plan to preview the changes that Terraform will apply.

Apply Terraform Configuration:

yaml
Skopiuj kod
- name: Terraform Apply
  id: apply
  run: terraform apply -auto-approve -input=false -parallelism=1 planfile
Applies the Terraform configuration to create the infrastructure.

Clean Up:

yaml
Skopiuj kod
- name: Clean up
  if: always()
  run: rm -f private_key.pem
Removes the SSH private key file to ensure security.

Get Host Public IP:

yaml
Skopiuj kod
- name: Get host public IP
  id: get_ip
  run: |
    echo "host_ip=$(terraform output -raw host_public_ip)" >> $GITHUB_OUTPUT         
Retrieves the public IP address of the host instance created by Terraform.

configure Job
The configure job sets up the host instance and configures the EKS cluster. It depends on the terraform job.

Job Configuration:

yaml
Skopiuj kod
jobs:
  configure:
    name: "Configure Host"
    runs-on: ubuntu-latest
    needs: terraform
    defaults:
      run:
        shell: bash
AWS CLI Setup:

yaml
Skopiuj kod
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
Configures the AWS CLI on the host instance with necessary credentials and region information.

Install Kubectl & Eksctl:

yaml
Skopiuj kod
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
Installs kubectl and eksctl on the host instance using the install.sh script.

Install Helm, ALB Controller, ArgoCD:

yaml
Skopiuj kod
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
Connects to the EKS cluster, associates IAM OIDC provider, and installs Helm, ALB controller, and ArgoCD using the install2.sh script.

Install Scripts
install.sh
This script installs the necessary tools on the host instance:

Install Dependencies:

bash
Skopiuj kod
sudo apt update -y >> /dev/null
sudo apt-get install -y apt-transport-https ca-certificates curl unzip jq
Install Kubectl:

bash
Skopiuj kod
sudo curl -LO "https://dl.k8s.io/release/v1.28.4/bin/linux/amd64/kubectl"
sudo chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client
Install Eksctl:

bash
Skopiuj kod
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
install2.sh
This script sets up the EKS cluster with various components:

Create IAM Policy and Service Account for ALB Controller:

bash
Skopiuj kod
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam-policy.json

eksctl create iamserviceaccount \
    --cluster=cvapp-eks \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --attach-policy-arn=arn:aws:iam::975510455885:policy/AWSLoadBalancerControllerIAMPolicy \
    --override-existing-serviceaccounts \
    --region=eu-central-1 \
    --approve
Create Namespaces:

bash
Skopiuj kod
kubectl create ns app
kubectl create ns monitoring
kubectl create ns argocd
Install ArgoCD:

bash
Skopiuj kod
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.7/manifests/install.yaml
sleep 15
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
Install Helm:

bash
Skopiuj kod
sudo snap install helm --classic
helm repo add eks https://aws.github.io/eks-charts
Install AWS Load Balancer Controller:

bash
Skopiuj kod
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=cvapp-eks --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller
Install Prometheus and Grafana:

bash
Skopiuj kod
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring
sleep 15
kubectl patch svc prometheus-kube-prometheus-prometheus -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'

helm repo add grafana https://grafana.github.io/helm-charts
helm install grafana grafana/grafana -n monitoring
sleep 15
kubectl patch svc grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
Output Important Information:

bash
Skopiuj kod
export ARGOCD_SERVER=`kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'`
export ARGOCD_PWD=`kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
export GRAFANA_SERVER=`kubectl get svc grafana -n monitoring -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'`
export GRAFANA_PWD=`kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 -d`
export PROMETHEUS_SERVER=`kubectl get svc prometheus-kube-prometheus-prometheus -n monitoring -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'`

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
Summary
This GitHub Actions workflow provides a robust mechanism for provisioning and configuring an EKS cluster using Terraform and additional scripts. It follows DevOps best practices, ensuring secure management of secrets, automated provisioning, and installation of necessary tools and services. The process is divided into clear steps that allow for easy debugging and maintenance, ensuring a reliable and repeatable deployment process.
