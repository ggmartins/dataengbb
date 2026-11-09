# Disposable test certificates. Private keys are stored in Terraform state.
resource "tls_private_key" "client_ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
resource "tls_self_signed_cert" "client_ca" {
  private_key_pem = tls_private_key.client_ca.private_key_pem
  subject { common_name = "ALB mTLS Lab Client CA" }
  validity_period_hours = 168
  is_ca_certificate     = true
  allowed_uses          = ["cert_signing", "crl_signing", "digital_signature"]
}
resource "tls_private_key" "client" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
resource "tls_cert_request" "client" {
  private_key_pem = tls_private_key.client.private_key_pem
  subject { common_name = "lab-client" }
}
resource "tls_locally_signed_cert" "client" {
  cert_request_pem      = tls_cert_request.client.cert_request_pem
  ca_private_key_pem    = tls_private_key.client_ca.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.client_ca.cert_pem
  validity_period_hours = 144
  allowed_uses          = ["client_auth", "digital_signature", "key_encipherment"]
}
resource "tls_private_key" "untrusted" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
resource "tls_self_signed_cert" "untrusted" {
  private_key_pem = tls_private_key.untrusted.private_key_pem
  subject { common_name = "untrusted-client" }
  validity_period_hours = 144
  allowed_uses          = ["client_auth", "digital_signature", "key_encipherment"]
}
resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
resource "tls_self_signed_cert" "server" {
  private_key_pem = tls_private_key.server.private_key_pem
  subject { common_name = var.hostname }
  dns_names             = [var.hostname]
  validity_period_hours = 168
  allowed_uses          = ["server_auth", "digital_signature", "key_encipherment"]
}
resource "aws_acm_certificate" "server" {
  private_key      = tls_private_key.server.private_key_pem
  certificate_body = tls_self_signed_cert.server.cert_pem
}
resource "random_id" "suffix" { byte_length = 4 }
resource "aws_s3_bucket" "ca" {
  bucket        = "${var.name}-ca-${random_id.suffix.hex}"
  force_destroy = true
}
resource "aws_s3_bucket_public_access_block" "ca" {
  bucket                  = aws_s3_bucket.ca.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_object" "ca" {
  bucket       = aws_s3_bucket.ca.id
  key          = "client-ca.pem"
  content      = tls_self_signed_cert.client_ca.cert_pem
  content_type = "application/x-pem-file"
}
resource "aws_lb_trust_store" "client" {
  name                             = "${var.name}-clients"
  ca_certificates_bundle_s3_bucket = aws_s3_bucket.ca.id
  ca_certificates_bundle_s3_key    = aws_s3_object.ca.key
  depends_on                       = [aws_s3_bucket_public_access_block.ca]
}
