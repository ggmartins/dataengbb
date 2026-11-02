# Standard Amazon EKS with Terraform

A conventional EKS baseline using private EC2 workers in an EKS managed node
group, with AWS-managed control plane and community VPC/EKS Terraform modules.
This is a useful starting architecture, not a claim of measured market share.

## Resources

| Component | Configuration |
| --- | --- |
| VPC | 10.0.0.0/16, three available Availability Zones |
| Public subnets | Three /24 subnets, Internet Gateway and NAT gateways |
| Private subnets | Three /20 subnets for nodes and pod IPs |
| NAT gateways | One per AZ by default; optional single gateway for labs |
| EKS | Kubernetes 1.36, private API plus public API restricted to admin CIDRs |
| EC2 workers | Managed node group, three m6i.large On-Demand instances initially |
| Worker OS | EKS-optimized Amazon Linux 2023 x86-64 |
| Node limits | Minimum two, initial desired three, maximum six |
| Add-ons | VPC CNI, CoreDNS, kube-proxy, EKS Pod Identity agent |
| Access | Terraform caller receives a cluster administrator access entry |
| Identity | IRSA enabled; Pod Identity agent installed |
| Logs | All five control-plane log types, 30-day retention |
| Subnet tags | Public/internal load-balancer discovery tags |

Node placement is spread by the managed node group's underlying Auto Scaling
group; three desired nodes does not guarantee one running node per AZ at all times.

## Requirements

- Terraform >= 1.5.7 and < 2.0; AWS provider >= 6.59 and < 7.0 (the module enforces the minimum).
- AWS CLI with credentials for an IAM role/user authorized to create VPC,
  EC2, IAM, EKS, CloudWatch Logs and KMS resources. Do not use root credentials.
- kubectl compatible with your chosen Kubernetes version.
- A region with at least three available AZs and supported EC2 instance types.
- A VPC CIDR that does not conflict with networks you intend to connect.

The EKS module is pinned to 21.26.0 and VPC to 6.7.3. The module provisions IAM,
security groups, and its default customer-managed KMS key for cluster secrets
encryption. Add-on versions are resolved for the selected Kubernetes version.

## Plan

```bash
cd eks-standard
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`: replace `203.0.113.10/32` with your public IPv4 CIDR.
The example address is a documentation placeholder and will not allow access
from your computer. Change the region, name and version as needed.

```bash
aws sts get-caller-identity
aws eks describe-cluster-versions --region us-east-1
terraform init
terraform fmt -check
terraform validate
terraform plan -out=eks.tfplan
```

Use your configured region in AWS CLI commands if different from us-east-1.
Plan reads AWS data and needs credentials but does not create the cluster.
Everything is one Terraform root module: no remote state from an earlier
deployment is required. Planning still checks real AWS APIs; it is not an
offline simulation.

## Apply and connect

Review the plan, then run:

```bash
terraform apply eks.tfplan
aws eks update-kubeconfig --region us-east-1 --name eks-standard
kubectl get nodes -o wide
kubectl get pods -A
```

Use the same IAM identity that ran Terraform apply for initial kubectl access.
For teams or CI, replace creator administration with explicit EKS access entries
for stable administrator roles. Access to the API requires both an allowed
network path and authorized AWS credentials.

## Limits and common next steps

- `min_size` and `max_size` do not install workload-based node autoscaling.
  Add Cluster Autoscaler or Karpenter when required. The EKS module ignores
  changes to `desired_size` after initial creation so an autoscaler can manage
  it. Change ongoing desired capacity through the node-group scaling API.
- Load-balancer subnet tags do not install the AWS Load Balancer Controller or
  create an ALB. Add the controller, its IAM role, and an Ingress separately.
- Pod Identity and IRSA support do not grant application AWS permissions.
  Assign each workload its own role and policy.
- EBS CSI and its IAM role are not included. Add them before using EBS-backed
  PersistentVolumeClaims. Define a gp3 StorageClass as appropriate.
- This example uses local Terraform state. Before team use, configure an
  existing protected S3 backend with state locking; do not commit state files.
- Add monitoring, application backups, network policies and workload-specific
  controls as your requirements dictate.
- After the cluster exists, manage Helm releases and applications separately
  so infrastructure planning does not require a working Kubernetes provider.

## Lab cost option

Before initial apply, set `single_nat_gateway = true` for one NAT gateway.
This lowers recurring gateway costs but introduces a shared AZ dependency
and potentially cross-AZ data charges. The default creates three gateways.
Changing this on an existing VPC changes private-subnet routes.

Applying creates billable EKS, EC2, EBS, NAT, public IPv4, logging and KMS
resources. No AWS resources were created while preparing these files.

## Destroy a lab

First delete application Ingresses/LoadBalancer Services and any controller-created
AWS resources; then:

```bash
terraform plan -destroy
terraform destroy
```

## References

- https://github.com/terraform-aws-modules/terraform-aws-eks
- https://github.com/terraform-aws-modules/terraform-aws-vpc
- https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html
- https://docs.aws.amazon.com/eks/latest/userguide/create-managed-node-group.html

## Validation

`terraform fmt -check` passed with Terraform 1.13.5. The pinned EKS and VPC
modules downloaded successfully. Full `terraform validate` was blocked by an
AWS provider package checksum mismatch that persisted after reinstallation;
provider checksum verification was not disabled. Run `terraform init` and
`terraform validate` locally before planning. Generated provider caches and
the authoring environment's lock file are excluded from this starter archive;
commit the lock file created by your own initialization. An AWS plan or apply
was not run in the authoring environment.
