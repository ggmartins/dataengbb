# Validation performed

Prepared on 2026-10-29. No AWS resources were created and no live EKS/ALB integration test was run.

Passed:

- `terraform fmt -check -recursive` with Terraform 1.13.5, covering HCL parsing and formatting.
- Offline Terraform plans of the actual annotation expressions, with infrastructure values substituted by fixture values, for `off`, `server`, `passthrough`, and `verify`. Checked listener JSON, mTLS modes, certificate annotation presence, and trust-store ARN inclusion. These checks do not validate provider resources.
- `bash -n` on the certificate-generation script.
- Ran the OpenSSL generation script, verified the server certificate for server authentication and the client certificate for client authentication. Test private keys and certificates are excluded from the bundle.
- Started the Python echo app locally and checked `/healthz`, JSON output, path/pod reporting, and certificate-header echoing.
- Fetched chart 3.6.2 from the official EKS chart repository; confirmed matching controller appVersion v3.6.2 and the chart's `controllerConfig.featureGates` setting.

Not completed:

- Full `terraform validate` could not finish in the execution environment: the Helm provider could not open its Unix-domain plugin socket (`operation not permitted`), and the downloaded AWS provider package failed the local cache checksum comparison. Provider installation was attempted, but this is not a successful provider-schema validation.
- AWS IAM authorization, EKS/node creation, controller readiness, ALB reconciliation, real client TLS handshakes, and teardown require running the lab in your sandbox account.

Run `terraform init` and `terraform validate` in each stage on your machine, then review the plan before applying. The included lock files record the provider selections from initialization; no provider executables or Terraform state are distributed.
