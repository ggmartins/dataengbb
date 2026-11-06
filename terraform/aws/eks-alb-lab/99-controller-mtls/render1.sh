#!/bin/bash

helm template cluster-level-resources . \
  --namespace argocd \
  --values alb-controller-mtls1-values.yaml \
  --show-only templates/alb-controller-mtls1.yaml

