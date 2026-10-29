# Minimal EKS + ALB Terraform lab

Reproduce the AWS Ingress pattern in Gen3's `helm/revproxy/templates/ingress_aws.yaml` with a small Python header-echo app standing in for revproxy. No Gen3 installation or DNS zone is required. Start with HTTP; optionally enable HTTPS and ALB mTLS.

Traffic: client → internet-facing ALB → pod IP:8080. A Kubernetes Service on port 80 selects the pods. With `target_type = "ip"`, the ALB targets the pod IPs directly; it does not send traffic through the Service's ClusterIP.

Control: Terraform creates the EKS cluster and installs the AWS Load Balancer Controller. Terraform then creates an Ingress. The controller reconciles that Ingress into an ALB, listeners, rules, target groups, target registrations, and security group rules. **Terraform does not create an `aws_lb` resource in this lab.**

## What is created

- A VPC with two public /24 subnets in different Availability Zones and an internet gateway.
- An EKS 1.35 cluster, one `t3.medium` managed worker with a 20 GiB disk, and managed networking add-ons.
- The controller, with a dedicated IAM role through IRSA; chart/controller version 3.6.2.
- Two echo pods, `revproxy-service`, and `revproxy-alb` Ingress in namespace `alb-lab`.
- Optional: an imported ACM server certificate and, for mTLS verify, a private S3 CA bundle and ALB trust store.

The nodes use public IPv4 addresses for outbound access, avoiding NAT gateway charges. The managed node group's default cluster security group handles internal communication; no SSH rule is created. The EKS API public endpoint and ALB inbound rules are restricted to your supplied IPv4 CIDR. The EKS private endpoint is also enabled so nodes can reach the API internally.

This is a disposable single-node lab, without high availability. It uses commercial AWS regions. Terraform state is local, and the optional imported server private key is included in app state. Keep state and generated keys private.

## Prerequisites

- Terraform 1.6+ (tested with 1.13.5), AWS CLI v2, and kubectl compatible with the cluster version.
- AWS credentials for a sandbox account with permission to create EKS, EC2/VPC, IAM, and ELB resources; optional TLS also uses ACM and S3.
- OpenSSL if exploring TLS. No Helm CLI is required: the Terraform Helm provider installs the controller.
- Use the **same AWS identity/profile** for Terraform, kubectl's AWS token helper, and cleanup. The cluster creator receives Kubernetes admin access.

Provider selections are recorded in the included `.terraform.lock.hcl` files. The AWS controller's IAM policy is vendored from the matching v3.6.2 release. When upgrading the controller, upgrade its IAM policy and follow the upstream CRD upgrade instructions together.

## 1. Create the cluster

Run all commands below from this directory unless indicated otherwise.

```bash
export AWS_PROFILE=your-sandbox-profile
aws sts get-caller-identity

cp 01-infra/terraform.tfvars.example 01-infra/terraform.tfvars
```

Edit `01-infra/terraform.tfvars`: replace the documentation address in `allowed_cidr` with your public IPv4 address and `/32`. You can retrieve the address with `curl -4 https://checkip.amazonaws.com`. Use the egress address of the machine running Terraform and curl, accounting for any VPN. Choose an available region and adjust the cluster name if needed.

```bash
terraform -chdir=01-infra init
terraform -chdir=01-infra apply

LAB_REGION=$(terraform -chdir=01-infra output -raw region)
LAB_NAME=$(terraform -chdir=01-infra output -raw name)
aws eks update-kubeconfig --region "$LAB_REGION" --name "$LAB_NAME" --alias "$LAB_NAME"
kubectl --context "$LAB_NAME" get nodes
```

Cluster/node provisioning commonly takes several minutes. Review the plan before approving `apply`.

## 2. Install the controller

```bash
terraform -chdir=02-controller init
terraform -chdir=02-controller apply
kubectl --context "$LAB_NAME" -n kube-system rollout status \
  deployment/aws-load-balancer-controller --timeout=180s
kubectl --context "$LAB_NAME" get ingressclass alb
```

The Helm release supplies the region and VPC explicitly so controller discovery does not depend on pod access to EC2 instance metadata. Gateway API features are disabled because this lab uses Ingress.

## 3. Deploy the app and Ingress

```bash
cp 03-app/terraform.tfvars.example 03-app/terraform.tfvars
terraform -chdir=03-app init
terraform -chdir=03-app apply

ALB_DNS=$(terraform -chdir=03-app output -raw alb_hostname)
curl --fail "http://$ALB_DNS/"
```

Expect JSON containing a pod name and request headers, including forwarded-protocol and forwarding-address headers. The Ingress waits for an ALB hostname, but DNS propagation and target health can take a little longer. If curl initially fails, inspect target health and retry after the targets are healthy.

Separate states allow the API and controller webhook to be ready before app creation. Keep all three directories and their state files together. If you move to a remote backend, update the two `terraform_remote_state` blocks accordingly.

## Relationship to Gen3

| Gen3 template setting | This lab |
| --- | --- |
| `ingressClassName: alb` | Same; the AWS controller reconciles it |
| `revproxy-service:80` | Same Service name and port, pointing to echo pods |
| `group.name` from environment/group | Unique cluster name as the group |
| `global.aws.scheme` | `internet-facing` |
| HTTP and HTTPS listeners plus ACM ARN | HTTP first; optional generated certificate enables HTTPS |
| Host rule from `global.hostname` | No host restriction for HTTP; `alb-lab.example.test` for TLS |
| No explicit target type | Lab explicitly defaults to `ip`; use `instance` to explore the controller default |
| `ingress.annotations` | Comparable ALB annotations are in `03-app/main.tf` |

To explore instance targets, set `target_type = "instance"` in `03-app/terraform.tfvars` and reapply. The lab automatically switches the Service to `NodePort`. Traffic then enters through a node's NodePort instead of targeting pod IPs directly. Switching target type may replace the target group and briefly interrupt traffic.

The Gen3 template inspected on 2026-10-29 defines an `actions.ssl-redirect` annotation, but its only backend is `revproxy-service:80`. That custom action needs a backend reference to `ssl-redirect` with port name `use-annotation` to be executed. This lab instead uses the simpler `alb.ingress.kubernetes.io/ssl-redirect: "443"` annotation when TLS is enabled.

An explicit IngressGroup shares one ALB across participating Ingresses. Only place trusted workloads in the same group, and coordinate listener-wide settings such as certificates and mTLS. Do not reuse a production Gen3 group name in this lab.

## Inspect the resulting AWS resources

```bash
kubectl --context "$LAB_NAME" -n alb-lab describe ingress revproxy-alb
kubectl --context "$LAB_NAME" -n alb-lab get ingress,svc,pods
kubectl --context "$LAB_NAME" -n alb-lab get targetgroupbindings
kubectl --context "$LAB_NAME" -n kube-system logs \
  deployment/aws-load-balancer-controller --tail=100

ALB_ARN=$(aws elbv2 describe-load-balancers --region "$LAB_REGION" \
  --names "$LAB_NAME" --query 'LoadBalancers[0].LoadBalancerArn' --output text)
aws elbv2 describe-listeners --region "$LAB_REGION" --load-balancer-arn "$ALB_ARN"
aws elbv2 describe-target-groups --region "$LAB_REGION" --load-balancer-arn "$ALB_ARN"
```

For a returned target group ARN:

```bash
aws elbv2 describe-target-health --region "$LAB_REGION" \
  --target-group-arn YOUR_TARGET_GROUP_ARN
```

Useful experiments: inspect listener rules, compare `ip` and `instance` targets, change the health-check path to see unhealthy targets, scale the Deployment, and compare TLS modes. Save desired changes in Terraform to avoid having reconciliation undo manual edits.

## Optional HTTPS and mTLS

Generate a seven-day lab server certificate plus a separate client CA and client certificate:

```bash
bash certs/generate.sh
```

For another hostname, pass it to the script and set the same `hostname` in `03-app/terraform.tfvars`. The script refuses to overwrite existing keys.

Set `tls_mode = "server"` in `03-app/terraform.tfvars`, then:

```bash
terraform -chdir=03-app apply
ALB_DNS=$(terraform -chdir=03-app output -raw alb_hostname)
LAB_HOST=$(terraform -chdir=03-app output -raw hostname)
curl --fail --cacert certs/server.crt \
  --connect-to "$LAB_HOST:443:$ALB_DNS:443" "https://$LAB_HOST/"
curl -I -H "Host: $LAB_HOST" "http://$ALB_DNS/"
```

`--connect-to` connects to the actual ALB while preserving the lab hostname for SNI, certificate verification, and the Host header. No DNS change or `--insecure` is needed. The HTTP request should receive a redirect to HTTPS.

Next set `tls_mode = "verify"` and `create_trust_store = true` in the app tfvars and reapply. Terraform uploads the client CA's public certificate to S3, creates a trust store, and passes its ARN to the Ingress. Wait for the listener to reconcile, then compare:

```bash
# Expected failure: no client certificate.
curl --fail --cacert certs/server.crt \
  --connect-to "$LAB_HOST:443:$ALB_DNS:443" "https://$LAB_HOST/"

# Expected success: client certificate signed by the trusted client CA.
curl --fail --cacert certs/server.crt \
  --cert certs/client.crt --key certs/client.key \
  --connect-to "$LAB_HOST:443:$ALB_DNS:443" "https://$LAB_HOST/"
```

The successful response should show `X-Amzn-Mtls-Clientcert-*` headers (header case may vary). In `verify` mode, the ALB validates the client certificate. In `passthrough` mode it forwards the certificate chain in a header and the application is responsible for certificate validation. ALB passthrough still terminates TLS at the ALB; it does not tunnel raw TLS to the pod. The echo app only displays headers and implements no authorization.

Use `server` to disable mTLS while retaining HTTPS: the lab explicitly sends mTLS mode `off`, which the controller requires when disabling previously enabled mTLS. Keep `create_trust_store = true` while changing TLS modes, so the trust store remains available during the asynchronous listener update. It will be removed during cleanup. If you want to remove it sooner, first change the mode and apply, wait for `aws elbv2 describe-listeners` to confirm that port 443 no longer references it, then set `create_trust_store = false` and apply again.

For the RAS integration, establish the TLS client/server direction. This lab covers incoming client → Gen3 ALB authentication. If Fence must present a client certificate to an NIH RAS endpoint, that connection is configured in Fence's outbound HTTP client. ALB certificate verification also does not implement OIDC login, token validation, or application authorization.

## Cleanup: keep the controller running until the ALB is deleted

Use the currently configured tfvars, and retrieve the ALB ARN **before** deleting its Ingress. If you opened a new shell, restore `AWS_PROFILE`, `LAB_REGION`, and `LAB_NAME` using the earlier commands.

```bash
ALB_ARN=$(aws elbv2 describe-load-balancers --region "$LAB_REGION" \
  --names "$LAB_NAME" --query 'LoadBalancers[0].LoadBalancerArn' --output text)
kubectl --context "$LAB_NAME" -n alb-lab delete ingress revproxy-alb --wait=true
aws elbv2 wait load-balancers-deleted --region "$LAB_REGION" \
  --load-balancer-arns "$ALB_ARN"

terraform -chdir=03-app destroy
terraform -chdir=02-controller destroy
terraform -chdir=01-infra destroy
```

Deleting the Ingress first lets the controller remove the ALB before Terraform removes an attached trust store or certificate. The subsequent app destroy refreshes its state and removes remaining resources. If no ALB was ever created, skip the ALB waiter. If deletion fails, inspect controller logs and resolve the failure before removing the controller or cluster. AWS VPC deletion can require a retry while load-balancer network interfaces finish disappearing.

## Cost and limits

EKS standard-support control plane pricing is $0.10/hour; EC2, EBS, ALB/LCUs, public IPv4, data transfer, and optional trust-store/S3 charges are additional. This lab avoids NAT and AWS Private CA. Destroy it after use; scaling the worker to zero would leave the control plane and ALB billable. Check pricing in your selected region.

No AWS resources were created while preparing this bundle. See `VALIDATION.md` for the checks actually performed.

## Sources

- Gen3 template: https://github.com/uc-cdis/gen3-helm/blob/master/helm/revproxy/templates/ingress_aws.yaml
- Controller installation: https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/deploy/installation/
- Exact IAM policy: https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v3.6.2/docs/install/iam_policy.json
- Controller annotations: https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/guide/ingress/annotations/
- AWS mTLS: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/mutual-authentication.html
- Terraform trust store: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_trust_store
- EKS versions: https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html
- EKS pricing: https://aws.amazon.com/eks/pricing/
