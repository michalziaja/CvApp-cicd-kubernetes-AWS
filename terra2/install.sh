#!/bin/bash


echo "Start Install Script"
sudo apt update -y >> /dev/null
sudo apt-get install -y apt-transport-https ca-certificates curl unzip jq

echo "Install Kubectl"
sudo apt update
sudo curl -LO "https://dl.k8s.io/release/v1.28.4/bin/linux/amd64/kubectl"
sudo chmod +x kubectl
sudo mv kubectl /usr/local/bin/
#kubectl version --client

echo "Install Eksctl"
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
#eksctl version

echo "Install Script Complete"