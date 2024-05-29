#!/bin/bash

echo "Start Install Script"

#aws eks update-kubeconfig --region eu-central-1 --name cvapp-eks

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

kubectl create ns app

echo "ArgoCD"
kubectl create ns argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.7/manifests/install.yaml
sleep 15
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'


sudo snap install helm --classic
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=cvapp-eks --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller
# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# helm install ingress-nginx ingress-nginx/ingress-nginx
kubectl create ns monitoring

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

echo "Install Docker"
sudo apt install docker.io -y >> /dev/null
sudo usermod -aG docker ubuntu
sudo systemctl enable --now docker

sleep 10
export GRAFANA_SERVER=`kubectl get svc grafana -n monitoring -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'`
export GRAFANA_PWD=`kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 -d`
export ARGOCD_SERVER=`kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'`
export ARGOCD_PWD=`kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
export PROMETHEUS_SERVER=`kubectl get svc prometheus-kube-prometheus-prometheus -n monitoring -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'`

sleep 5
echo "########## HOST IP ##########"
curl ifconfig.me; echo
echo "########## ArgoCD Server ##########"
echo $ARGOCD_SERVER
echo
echo "########## ArgoCD Pass ##########"
echo $ARGOCD_PWD
echo
echo "########## Grafana Server ##########"
echo $GRAFANA_SERVER
echo
echo "########## Grafana Pass ##########"
echo $GRAFANA_PWD
echo
echo "########## Prometheus Server ##########"
echo $PROMETHEUS_SERVER
echo
echo "Install Script Complete"