data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required", "opted-in"]
  }
}

locals {
  azs = slice(sort(data.aws_availability_zones.available.names), 0, 3)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = local.azs
  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.16.0/20", "10.0.32.0/20", "10.0.48.0/20"]

  enable_dns_support   = true
  enable_dns_hostnames = true

  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = !var.single_nat_gateway

  # Subnet discovery tags for a future AWS Load Balancer Controller.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.26.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Nodes reach the private API endpoint; administrators use the restricted
  # public endpoint. Worker EC2 instances do not receive public IP addresses.
  endpoint_private_access      = true
  endpoint_public_access       = true
  endpoint_public_access_cidrs = var.admin_cidrs

  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = true

  enabled_log_types                      = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = 30

  addons = {
    vpc-cni = {
      before_compute = true
    }
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    coredns    = {}
  }

  eks_managed_node_groups = {
    general = {
      name           = "general"
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["m6i.large"]
      capacity_type  = "ON_DEMAND"

      min_size     = 2
      desired_size = 3
      max_size     = 6

      labels = {
        workload = "general"
      }

      update_config = {
        max_unavailable = 1
      }
    }
  }
}
