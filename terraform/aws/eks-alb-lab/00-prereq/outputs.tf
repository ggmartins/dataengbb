output "certificateArn" {
  description = "Set alb-controller-mtls.ingress.certificateArn to this value."
  value       = aws_acm_certificate.server.arn
}
output "trustStore" {
  description = "Set alb-controller-mtls.ingress.trustStore to this ELB trust-store ARN."
  value       = aws_lb_trust_store.client.arn
}
output "helm_values" {
  value = {
    "alb-controller-mtls" = {
      ingress = {
        certificateArn = aws_acm_certificate.server.arn
        trustStore     = aws_lb_trust_store.client.arn
        hostname       = var.hostname
      }
    }
  }
}
output "client_files" {
  sensitive = true
  value = {
    "client-ca.crt" = tls_self_signed_cert.client_ca.cert_pem
    "client.crt"    = tls_locally_signed_cert.client.cert_pem
    "client.key"    = tls_private_key.client.private_key_pem
    "untrusted.crt" = tls_self_signed_cert.untrusted.cert_pem
    "untrusted.key" = tls_private_key.untrusted.private_key_pem
    "server.crt"    = tls_self_signed_cert.server.cert_pem
  }
}
