terraform {
  required_version = ">= 1.6.0, < 2.0.0"
  required_providers {
    helm = { source = "hashicorp/helm", version = "~> 2.17.0" }
  }
}

data "terraform_remote_state" "infra" {
  backend = "local"
  config  = { path = "${path.module}/../01-infra/terraform.tfstate" }
}

locals { infra = data.terraform_remote_state.infra.outputs }

provider "helm" {
  kubernetes {
    host                   = local.infra.endpoint
    cluster_ca_certificate = base64decode(local.infra.cluster_ca)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.infra.name, "--region", local.infra.region]
    }
  }
}

resource "helm_release" "controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "3.6.2"
  namespace  = "kube-system"
  wait       = true
  atomic     = true
  timeout    = 600

  values = [yamlencode({
    clusterName  = local.infra.name
    region       = local.infra.region
    vpcId        = local.infra.vpc_id
    replicaCount = 1
    serviceAccount = {
      create      = true
      name        = "aws-load-balancer-controller"
      annotations = { "eks.amazonaws.com/role-arn" = local.infra.controller_role_arn }
    }
    # This lab uses Ingress; Gateway API CRDs are unnecessary with these disabled.
    controllerConfig = { featureGates = { ALBGatewayAPI = false, NLBGatewayAPI = false } }
  })]
}
