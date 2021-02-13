variable "region" {
  default     = "us-central1"
  description = "GC region"
}

variable "environment" {
  description = "Devops Environment (ie. Prod/Stage)"
  type        = string
}

locals {
  cluster_name = "gke-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}