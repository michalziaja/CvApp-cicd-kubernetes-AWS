#!/bin/bash

echo "Start Install Script"


curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam-policy.json

eksctl create iamserviceaccount \
    --cluster=cvapp-eks \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --attach-policy-arn=arn:aws:iam::975510455885:policy/AWSLoadBalancerControllerIAMPolicy \
    --override-existing-serviceaccounts \
    --region=eu-central-1 \
    --approve

echo "Create Namespaces"
kubectl create ns app
kubectl create ns monitoring
kubectl create ns argocd


echo "Install ArgoCD"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.7/manifests/install.yaml
sleep 15
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

echo "Install Helm"
sudo snap install helm --classic
helm repo add eks https://aws.github.io/eks-charts

echo "Install Load Balancer Controler"
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=cvapp-eks --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller

# echo "Install Nginx Ingress"
# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# helm install ingress-nginx ingress-nginx/ingress-nginx


sleep 15
echo "Install Prometheus"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring
sleep 15
kubectl patch svc prometheus-kube-prometheus-prometheus -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'


echo "Install Grafana"
helm repo add grafana https://grafana.github.io/helm-charts
helm install grafana grafana/grafana -n monitoring
sleep 15
kubectl patch svc grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'

helm repo update

sleep 15
export ARGOCD_SERVER=`kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'`
export ARGOCD_PWD=`kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
export GRAFANA_SERVER=`kubectl get svc grafana -n monitoring -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'`
export GRAFANA_PWD=`kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 -d`
export PROMETHEUS_SERVER=`kubectl get svc prometheus-kube-prometheus-prometheus -n monitoring -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'`

sleep 10
echo "##################################"
echo "__________________________________"
echo "########## OUTPUTS ##########"
echo "__________________________________"
echo "########## HOST IP ##########"
echo "__________________________________"
wget -qO- ifconfig.me
echo "__________________________________"
echo "########## ArgoCD Server ##########"
echo "__________________________________"
echo $ARGOCD_SERVER
echo "__________________________________"
echo "########## ArgoCD Pass ##########"
echo "__________________________________"
echo $ARGOCD_PWD
echo "__________________________________"
echo "########## Grafana Server ##########"
echo "__________________________________"
echo $GRAFANA_SERVER
echo "__________________________________"
echo "########## Grafana Pass ##########"
echo "__________________________________"
echo $GRAFANA_PWD
echo "__________________________________"
echo "########## Prometheus Server ##########"
echo "__________________________________"
echo $PROMETHEUS_SERVER
echo "__________________________________"
