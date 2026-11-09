variable "region" {
  type        = string
  default     = "us-east-1"
  description = "Use the same AWS region as your existing ALB."
}
variable "name" {
  type    = string
  default = "alb-mtls-test"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,19}$", var.name))
    error_message = "Use 3-20 lowercase letters, numbers or hyphens, starting with a letter."
  }
}
variable "hostname" {
  type        = string
  default     = "mtls.lab.test"
  description = "Must match the hostname configured on your test Ingress."
}
