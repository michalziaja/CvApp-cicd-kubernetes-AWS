#!/bin/bash


echo "Start Install Script"
sudo apt update -y >> /dev/null

echo "Install AWS CLI"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y >> /dev/null
unzip awscliv2.zip >> /dev/null
sudo ./aws/install

echo "TEST AWS CLI"
aws s3api list-buckets

echo "Install Docker"
sudo apt install docker.io -y >> /dev/null
sudo usermod -aG docker ubuntu
sudo systemctl enable --now docker

echo "Install Kubectl"
sudo apt update
sudo curl -LO "https://dl.k8s.io/release/v1.28.4/bin/linux/amd64/kubectl"
sudo chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client

echo "Install Eksctl"
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version

echo "Install Argo CD"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.7/manifests/install.yaml
sudo apt install jq -y

echo "Install Helm"
sudo snap install helm --classic
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

echo "Install Prometheus"
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace

echo "Install Grafana"
helm install grafana grafana/grafana --namespace monitoring --create-namespace

echo "Install ingress-nginx"
helm install ingress-nginx ingress-nginx/ingress-nginx

echo "Install Script Complete"