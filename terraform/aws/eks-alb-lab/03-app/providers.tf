terraform {
  required_version = ">= 1.6.0, < 2.0.0"
  required_providers {
    aws        = { source = "hashicorp/aws", version = "~> 6.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.38.0" }
  }
}

data "terraform_remote_state" "infra" {
  backend = "local"
  config  = { path = "${path.module}/../01-infra/terraform.tfstate" }
}

locals { infra = data.terraform_remote_state.infra.outputs }

provider "aws" {
  region = local.infra.region
  default_tags { tags = { Project = local.infra.name, Environment = "lab" } }
}

provider "kubernetes" {
  host                   = local.infra.endpoint
  cluster_ca_certificate = base64decode(local.infra.cluster_ca)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", local.infra.name, "--region", local.infra.region]
  }
}

variable "tls_mode" {
  description = "off = HTTP; server = HTTPS; passthrough = forward client cert; verify = ALB validates client cert."
  type        = string
  default     = "off"
  validation {
    condition     = contains(["off", "server", "passthrough", "verify"], var.tls_mode)
    error_message = "Choose off, server, passthrough, or verify."
  }
}

variable "target_type" {
  type    = string
  default = "ip"
  validation {
    condition     = contains(["ip", "instance"], var.target_type)
    error_message = "Choose ip or instance."
  }
}

variable "hostname" {
  type    = string
  default = "alb-lab.example.test"
}

variable "create_trust_store" {
  description = "Create and retain the lab client CA trust store. Required for verify mode."
  type        = bool
  default     = false
}
