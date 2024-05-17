#!/bin/bash


echo "Start Install Script"
sudo apt update -y >> /dev/null

echo "Install AWS CLI"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y >> /dev/null
unzip awscliv2.zip >> /dev/null
sudo ./aws/install

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

echo "Install Script Complete"