#!/bin/bash

terraform -chdir=01-infra init
terraform -chdir=01-infra plan -out=infra.tfplan

terraform -chdir=02-controller init
terraform -chdir=02-controller test -filter=tests/plan.tftest.hcl

bash certs/generate.sh

terraform -chdir=03-app init
terraform -chdir=03-app test -filter=tests/plan.tftest.hcl -verbose



