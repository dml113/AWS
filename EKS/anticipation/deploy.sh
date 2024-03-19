#!/bin/bash
# ECR 로그인 후 image 업로드하고, 아래 명령어들 실행

# secrets 생성
docker login 950274644703.dkr.ecr.ap-northeast-2.amazonaws.com/lee-ecr
kubectl create secret generic regcred \
    --from-file=.dockerconfigjson=/home/ec2-user/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson
kubectl get secret regcred --output=yaml

# policy부터 생성한다. 
# account 생성
eksctl create iamserviceaccount --cluster EKS-clusters --attach-policy-arn arn:aws:iam::950274644703:policy/SecretsManagerPolicy --namespace default --name secret-role --approve

# deploy 해준다.
kubectl apply -f mainifest/deployment.yaml

# alb controller 생성
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

eksctl create iamserviceaccount \
  --cluster=EKS-clusters \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::950274644703:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve \
  --region ap-northeast-2

helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=EKS-clusters \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller 

kubectl get deployment -n kube-system aws-load-balancer-controller

# service 생성
kubectl apply -f mainifest/service.yaml

# ingress 생성
kubectl apply -f mainifest/ingress.yaml
