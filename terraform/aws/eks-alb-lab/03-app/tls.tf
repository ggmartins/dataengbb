# Optional, disposable lab PKI. Private server key is stored in Terraform state.
# Run ../certs/generate.sh before setting tls_mode to anything other than off.
locals {
  enable_tls   = var.tls_mode != "off"
  enable_trust = var.create_trust_store
}

data "aws_caller_identity" "current" {}

resource "aws_acm_certificate" "server" {
  count            = local.enable_tls ? 1 : 0
  private_key      = fileexists("${path.module}/../certs/server.key") ? file("${path.module}/../certs/server.key") : null
  certificate_body = fileexists("${path.module}/../certs/server.crt") ? file("${path.module}/../certs/server.crt") : null
}

resource "aws_s3_bucket" "ca" {
  count         = local.enable_trust ? 1 : 0
  bucket        = "${local.infra.name}-ca-${data.aws_caller_identity.current.account_id}-${local.infra.region}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "ca" {
  count                   = local.enable_trust ? 1 : 0
  bucket                  = aws_s3_bucket.ca[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "ca" {
  count  = local.enable_trust ? 1 : 0
  bucket = aws_s3_bucket.ca[0].id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_object" "ca" {
  count        = local.enable_trust ? 1 : 0
  bucket       = aws_s3_bucket.ca[0].id
  key          = "client-ca.pem"
  source       = "${path.module}/../certs/client-ca.crt"
  source_hash  = fileexists("${path.module}/../certs/client-ca.crt") ? filemd5("${path.module}/../certs/client-ca.crt") : null
  content_type = "application/x-pem-file"
  depends_on   = [aws_s3_bucket_versioning.ca]
}

resource "aws_lb_trust_store" "client" {
  count                                    = local.enable_trust ? 1 : 0
  name                                     = "${local.infra.name}-client-ca"
  ca_certificates_bundle_s3_bucket         = aws_s3_bucket.ca[0].id
  ca_certificates_bundle_s3_key            = aws_s3_object.ca[0].key
  ca_certificates_bundle_s3_object_version = aws_s3_object.ca[0].version_id
}
