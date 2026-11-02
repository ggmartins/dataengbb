variable "aws_region" {
  description = "AWS deployment region; the ACM server certificate must be in this region."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name prefix for the Lambda function, execution role, and HTTP API."
  type        = string
  default     = "mtls-lambda-example"

  validation {
    condition     = can(regex("^[A-Za-z0-9_-]{1,50}$", var.name))
    error_message = "Use 1 to 50 letters, digits, underscores, or hyphens."
  }
}

variable "domain_name" {
  description = "Custom API hostname covered by the ACM server certificate."
  type        = string
  default     = "mtls.example.com"
}

variable "certificate_arn" {
  description = "ARN of an existing issued public ACM server certificate in aws_region."
  type        = string
}

variable "hosted_zone_id" {
  description = "ID of the existing Route 53 public hosted zone containing domain_name."
  type        = string
}

variable "truststore_uri" {
  description = "S3 URI of an existing PEM truststore containing the trusted client CA chain."
  type        = string

  validation {
    condition     = can(regex("^s3://[^/]+/.+$", var.truststore_uri))
    error_message = "Use an S3 object URI such as s3://my-bucket/truststore.pem."
  }
}

variable "truststore_version" {
  description = "Optional S3 object version ID. Change this after updating a versioned truststore."
  type        = string
  default     = null
  nullable    = true
}
