#!/bin/bash


#latest helm: https://jupyterhub.github.io/helm-chart/#development-releases-binderhub
helm install jupyterhub/binderhub --version=0.2.0-n472.h32e06ee --generate-name -f secret.yaml -f config.yaml
