# Terraform mTLS Lambda endpoint

Deploy `GET https://mtls.example.com/hello` with API Gateway HTTP API, a Python
Lambda function, and a Route 53 alias record. API Gateway validates the client
certificate before invoking Lambda. The Lambda receives certificate metadata
in the HTTP API payload 2.0 event.

## Prerequisites

- Terraform >= 1.5 and < 2.0, plus AWS credentials for the target account.
- An existing Route 53 public hosted zone with working DNS delegation.
- An issued **public ACM server certificate** covering your hostname, in the
  same AWS region as this deployment. This example assumes an ACM-issued public
  certificate; imported or ACM Private CA server certificates require an
  additional ownership verification certificate configuration.
- An existing S3 bucket and PEM truststore accessible to the deploying principal
  and API Gateway. The truststore contains the complete trusted **client CA**
  chain from the issuing CA through the root. Do not upload private keys.
- A client certificate issued by a trusted CA and its corresponding private key.

The ACM server certificate identifies the API to clients. The S3 truststore
controls which client certificates the API accepts; these are separate roles.

## Deploy

If your client is signed directly by a root CA, upload that public CA certificate:

```bash
aws s3 cp client-ca.pem s3://YOUR-TRUSTSTORE-BUCKET/truststore.pem
```

For an intermediate issuing CA, include the intermediate and root CA
certificates together in `truststore.pem` before uploading.

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your actual values.
terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan
```

Review the plan, then create the resources:

```bash
terraform apply tfplan
terraform output -raw endpoint
```

`terraform plan` does not create AWS infrastructure. It does use AWS credentials
and can make read calls; the archive data source creates a local `lambda.zip`.
The project reuses the existing certificate, hosted zone, bucket, and truststore;
Terraform does not manage their lifecycles. Choose an unused custom hostname and
resource name, or explicitly import existing managed resources before applying.

## Call and verify

Wait for the custom domain and DNS to become available, then call:

```bash
curl --fail-with-body \
  --cert client.pem \
  --key client.key \
  "$(terraform output -raw endpoint)"
```

If the client certificate was issued by an intermediate CA, `client.pem` should
include the client leaf certificate followed by the intermediate certificates.
Keep normal server certificate verification enabled; do not use `curl -k`.

Expected response:

```json
{
  "message": "Hello from an mTLS-protected Lambda",
  "client_subject": "CN=my-client",
  "client_issuer": "CN=my-client-ca",
  "client_serial": "..."
}
```

Without the client certificate, API Gateway must reject the request before
invoking Lambda:

```bash
curl -v "$(terraform output -raw endpoint)"
```

An expired or untrusted client certificate must also fail. The default
`execute-api` endpoint is disabled to require the mTLS custom domain.

## Authentication and operation

- Any valid client certificate chaining to a trusted CA can call this demo.
  Add a Lambda authorizer or application checks for per-client permissions.
- API Gateway does not automatically check client certificate revocation.
- The handler checks certificate metadata defensively; API Gateway performs
  the actual TLS authentication. No separate Lambda Function URL is created.
- Lambda permissions grant this API permission to invoke only `GET /hello`.
- Lambda's role can write only to this function's pre-created log group;
  log retention is 14 days.
- For truststore rotation, enable S3 bucket versioning, upload the revised
  CA bundle, and update `truststore_version` to its new version ID before
  applying. Overwriting the same unversioned S3 key alone does not produce a
  Terraform domain update.
- Terraform state is local by default. Use a remote backend for shared use.

## Clean up

```bash
terraform destroy
```

This removes managed resources, including the function log group. Existing
ACM certificates, the hosted zone, and S3 truststore remain.

## References

- [AWS HTTP API mutual TLS](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-mutual-tls.html)
- [AWS HTTP API Lambda event format](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-lambda.html)
- [Terraform custom domain resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_domain_name)
- [Terraform Lambda integration resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration)

## Validation of this deliverable

`terraform fmt -check` and local handler checks passed, including missing
certificate rejection and certificate metadata in a successful response.
`terraform validate` was attempted but blocked by a downloaded AWS provider
package checksum mismatch in the authoring environment. The download omits
that provider cache and its lock file; run `terraform init` and
`terraform validate` locally to verify the provider schema. No AWS plan,
deployment, or live mTLS request was performed.
