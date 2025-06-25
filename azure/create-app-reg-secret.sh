#!/bin/bash
APP_NAME=AppTest
RG_NAME=rg_apptest
RG_RESULT=$(az group list --query "[?name=='${RG_NAME}'].name" -o tsv)
if [ -z "$RG_RESULT" ]; then
  az group create --name $RG_NAME
else
  echo "INFO: resource group ${RG_NAME} already created"
fi
az ad app create --display-name $APP_NAME
APP_ID=$(az ad app list --filter "displayName eq '${APP_NAME}'" --query "[0].appId" -o tsv)
echo -e "INFO: $APP_NAME = ${APP_ID}"
az ad app credential reset --id $APP_ID --append | tee create-app-reg-secret.json
az ad sp create --id $APP_ID
SP_ID=$(az ad sp list --filter "appId eq '${APP_ID}'" --query '[].id' -o tsv)
echo -e "INFO: $APP_NAME (SP_ID) = ${SP_ID}"
RESOURCE_GROUP=$(az group show --name $RG_NAME --query id -o tsv)
az role assignment create  --assignee-object-id $SP_ID --role Reader --scope $RESOURCE_GROUP
echo "USE: az group delete --name $RG_NAME TO DELETE THE RESOURCE GROUP" | tee -a create-app-reg-secret.log
echo "USE: az ad app delete --id $APP_ID TO DELETE THE APP REGISTRATION" | tee -a create-app-reg-secret.log

