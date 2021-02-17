#!/bin/bash

#UPDATE binderhub helm chart to the latest version
#https://jupyterhub.github.io/helm-chart/#development-releases-binderhub
BINDERHUB_VERSION=0.2.0-n514.h9fb668d
BINDERHUB_CONFIG=config.yaml
EKSCTL_CONFIG=aws_eks_config.yml
EKSCTL_SECRET=secret.yaml

#EXIT ON ERROR
set -e

#leave MACOS empty if you're running from linux
MACOS=

if [[ "$OSTYPE" == "darwin"* ]];then
  MACOS="''"
fi

if [ ! -f "$BINDERHUB_CONFIG" ];then
  echo "binderhub config not found: $BINDERHUB_CONFIG"
  exit 1
fi

echo "INFO: commenting hub_url line"
sed -i $MACOS '/hub_url/s/^/#/' $BINDERHUB_CONFIG

if [ ! -f "$EKSCTL_CONFIG" ];then
  echo "eksctl config not found: $EKSCTL_CONFIG"
  exit 1
fi

if [ ! -f "$EKSCTL_SECRET" ];then
  echo "eksctl secret file not found: $EKSCTL_SECRET"
  exit 1
fi

echo "INFO: creating eks cluster..."
eksctl create cluster --config-file $EKSCTL_CONFIG --verbose=4 > log_eksctl_create_cluster.log

echo "INFO: installing binderhub helm chart"
helm install jupyterhub/binderhub --version=$BINDERHUB_VERSION --generate-name -f $EKSCTL_SECRET -f $BINDERHUB_CONFIG > log_helm_install_binderhub.log

echo "INFO: updating helm repo"
helm repo update

HELM_NAME=$(cat log_helm_install_binderhub.log| grep NAME: | awk '{print $2}')
echo "INFO: helm name: $HELM_NAME"

KUBE_PROXY="<pending>"

while [[ $KUBE_PROXY == "<pending>" ]]; do
	kubectl --namespace=default get svc proxy-public > log_kubectl_get_svc_proxy_public.log

	KUBE_PROXY=$(cat ./log_kubectl_get_svc_proxy_public.log | grep proxy-public | awk '{ print $4 }')
	sleep 5
	echo "INFO: waiting on proxy-public address: $KUBE_PROXY"
done

echo "INFO: kubectl proxy-public: $KUBE_PROXY"

sed -i $MACOS "s/.*hub_url.*/    hub_url: http:\/\/${KUBE_PROXY}/" config.yaml

helm upgrade $HELM_NAME jupyterhub/binderhub --version=$BINDERHUB_VERSION -f $EKSCTL_SECRET -f $BINDERHUB_CONFIG > log_helm_upgrade_binderhub.log

kubectl --namespace=default get svc binder > log_kubectl_get_svc_binder.log

cat log_kubectl_get_svc_binder.log 
