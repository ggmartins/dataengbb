#!/bin/bash

#UPDATE binderhub helm chart to the latest version
#https://jupyterhub.github.io/helm-chart/#development-releases-binderhub
#https://zero-to-jupyterhub.readthedocs.io/en/latest/kubernetes/google/step-zero-gcp.html
BINDERHUB_VERSION=0.2.0-n499.h81660eb
BINDERHUB_CONFIG=config.yaml
JPYHUB_SECRET=secret.yaml
GCUSEREMAIL=

#EXIT ON ERROR
set -e

#leave MACOS empty if you're running from linux
MACOS=

#bash trick to check unset vars
if [ -z ${GCUSEREMAIL+x} ]; then echo "ERROR: GCUSEREMAIL is unset"; fi

if [[ "$OSTYPE" == "darwin"* ]];then
  MACOS="''"
fi

if [ ! -f "$BINDERHUB_CONFIG" ];then
  echo "binderhub config not found: $BINDERHUB_CONFIG"
  exit 1
fi

echo "INFO: commenting hub_url line"
sed -i $MACOS '/hub_url/s/^/#/' $BINDERHUB_CONFIG

if [ ! -f "$JPYHUB_SECRET" ];then
  echo "eksctl secret file not found: $JPYHUB_SECRET"
  exit 1
fi

echo "INFO: enabling gcloud..."
gcloud services enable cloudapis.googleapis.com
gcloud services enable container.googleapis.com

echo "INFO: creating gke cluster..."
gcloud container clusters create  --machine-type n1-standard-2  --num-nodes 2  --zone us-central1-a  --cluster-version latest  odp-cluster-test > log_gke_create_cluster.log
kubectl get node

kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$GCUSEREMAIL

echo "INFO: creating gke node pools cluster..."
gcloud beta container node-pools create user-pool \
   --machine-type n1-standard-2 \
   --num-nodes 0 \
   --enable-autoscaling \
   --min-nodes 0 \
   --max-nodes 3 \
   --node-labels hub.jupyter.org/node-purpose=user \
   --node-taints hub.jupyter.org_dedicated=user:NoSchedule \
   --zone us-central1-a \
   --cluster odp-cluster-test

echo "INFO: installing binderhub helm chart"
helm install jupyterhub/binderhub --version=$BINDERHUB_VERSION --generate-name -f $JPYHUB_SECRET -f $BINDERHUB_CONFIG > log_helm_install_binderhub.log

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

helm upgrade $HELM_NAME jupyterhub/binderhub --version=$BINDERHUB_VERSION -f $JPYHUB_SECRET -f $BINDERHUB_CONFIG > log_helm_upgrade_binderhub.log

kubectl --namespace=default get svc binder > log_kubectl_get_svc_binder.log

cat log_kubectl_get_svc_binder.log 
