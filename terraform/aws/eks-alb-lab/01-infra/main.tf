terraform {
  required_version = ">= 1.6.0, < 2.0.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
    tls = { source = "hashicorp/tls", version = "~> 4.0" }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name" {
  type    = string
  default = "eks-alb-lab"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,19}$", var.name))
    error_message = "Use a lowercase name of at most 20 characters."
  }
}

variable "kubernetes_version" {
  type    = string
  default = "1.35"
}

variable "allowed_cidr" {
  description = "Your public IPv4 CIDR, usually x.x.x.x/32; used for the API and lab ALB."
  type        = string
  validation {
    condition     = can(cidrnetmask(var.allowed_cidr)) && var.allowed_cidr != "0.0.0.0/0"
    error_message = "Supply a restricted IPv4 CIDR such as your public address followed by /32."
  }
}

provider "aws" {
  region = var.region
  default_tags { tags = { Project = var.name, Environment = "lab" } }
}

data "aws_availability_zones" "available" { state = "available" }
data "aws_partition" "current" {}

resource "aws_vpc" "lab" {
  cidr_block           = "10.42.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = var.name }
}

resource "aws_internet_gateway" "lab" { vpc_id = aws_vpc.lab.id }

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.lab.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(aws_vpc.lab.cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name                                = "${var.name}-public-${count.index}"
    "kubernetes.io/role/elb"            = "1"
    "kubernetes.io/cluster/${var.name}" = "shared"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab.id
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_iam_role" "cluster" {
  name = "${var.name}-cluster"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "eks.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "lab" {
  name     = var.name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version
  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }
  upgrade_policy { support_type = "STANDARD" }
  vpc_config {
    subnet_ids              = aws_subnet.public[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = [var.allowed_cidr]
  }
  depends_on = [aws_iam_role_policy_attachment.cluster]
}

resource "aws_iam_role" "nodes" {
  name = "${var.name}-nodes"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "nodes" {
  for_each   = toset(["AmazonEKSWorkerNodePolicy", "AmazonEC2ContainerRegistryReadOnly", "AmazonEKS_CNI_Policy"])
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/${each.value}"
}

resource "aws_eks_node_group" "lab" {
  cluster_name    = aws_eks_cluster.lab.name
  node_group_name = "lab"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = aws_subnet.public[*].id
  ami_type        = "AL2023_x86_64_STANDARD"
  instance_types  = ["t3.medium"]
  disk_size       = 20
  capacity_type   = "ON_DEMAND"
  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }
  depends_on = [aws_iam_role_policy_attachment.nodes, aws_route_table_association.public]
}

# Migrate the bootstrap networking add-ons to EKS-managed add-ons.
resource "aws_eks_addon" "networking" {
  for_each                    = toset(["vpc-cni", "kube-proxy", "coredns"])
  cluster_name                = aws_eks_cluster.lab.name
  addon_name                  = each.value
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.lab]
}

data "tls_certificate" "oidc" { url = aws_eks_cluster.lab.identity[0].oidc[0].issuer }

resource "aws_iam_openid_connect_provider" "lab" {
  url             = aws_eks_cluster.lab.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
}

locals { oidc_hostpath = replace(aws_eks_cluster.lab.identity[0].oidc[0].issuer, "https://", "") }

resource "aws_iam_role" "controller" {
  name = "${var.name}-lbc"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.lab.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = { StringEquals = {
        "${local.oidc_hostpath}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        "${local.oidc_hostpath}:aud" = "sts.amazonaws.com"
      } }
    }]
  })
}

# Upstream v3.6.2 policy, vendored without modification; see README for source.
resource "aws_iam_policy" "controller" {
  name   = "${var.name}-lbc"
  policy = file("${path.module}/controller-iam-policy.json")
}

resource "aws_iam_role_policy_attachment" "controller" {
  role       = aws_iam_role.controller.name
  policy_arn = aws_iam_policy.controller.arn
}

output "region" { value = var.region }
output "name" { value = var.name }
output "allowed_cidr" { value = var.allowed_cidr }
output "vpc_id" { value = aws_vpc.lab.id }
output "public_subnet_ids" { value = aws_subnet.public[*].id }
output "endpoint" { value = aws_eks_cluster.lab.endpoint }
output "cluster_ca" { value = aws_eks_cluster.lab.certificate_authority[0].data }
output "controller_role_arn" { value = aws_iam_role.controller.arn }
output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${var.name} --alias ${var.name}"
}
