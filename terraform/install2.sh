#!/bin/bash


echo "Start Install Script"

echo "TEST AWS CLI"
aws s3api list-buckets

echo "Install Docker"
sudo apt install docker.io -y >> /dev/null
sudo usermod -aG docker ubuntu
sudo systemctl enable --now docker

kubectl create ns app
echo "ArgoCD"
kubectl create ns argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.7/manifests/install.yaml
sudo apt install jq -y
kubectl get pods -n argocd
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
echo "Helm"
sudo snap install helm --classic
helm repo add eks https://aws.github.io/eks-charts
#helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
#helm install ingress-nginx ingress-nginx/ingress-nginx




echo "Install Argo CD"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.7/manifests/install.yaml
sudo apt install jq -y

export ARGOCD_SERVER=`kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'`
export ARGOCD_PWD=`kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
echo $ARGOCD_SERVER
echo $ARGOCD_PWD

# echo "Install Helm"
# sudo snap install helm --classic
# helm repo add eks https://aws.github.io/eks-charts
# helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
# helm repo add grafana https://grafana.github.io/helm-charts
# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# helm repo update

# echo "Install Prometheus"
# helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace

# echo "Install Grafana"
# helm install grafana grafana/grafana --namespace monitoring --create-namespace

# echo "Install ingress-nginx"
# helm install ingress-nginx ingress-nginx/ingress-nginx

echo "Install Script Complete"