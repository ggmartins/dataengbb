variable "aws_region" {
  description = "AWS region containing at least three available Availability Zones."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster and prefix for network resources."
  type        = string
  default     = "eks-standard"
}

variable "environment" {
  description = "Environment resource tag."
  type        = string
  default     = "dev"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes minor version; check regional availability before applying."
  type        = string
  default     = "1.36"
}

variable "admin_cidrs" {
  description = "Public IPv4 CIDRs allowed to reach the Kubernetes API, such as your public IP/32."
  type        = list(string)

  validation {
    condition = length(var.admin_cidrs) > 0 && alltrue([
      for cidr in var.admin_cidrs : can(cidrnetmask(cidr)) && cidr != "0.0.0.0/0"
    ])
    error_message = "Provide at least one valid IPv4 CIDR; do not use 0.0.0.0/0."
  }
}

variable "single_nat_gateway" {
  description = "True uses one NAT gateway to reduce lab cost; false uses one per AZ."
  type        = bool
  default     = false
}
