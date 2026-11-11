resource "aws_iam_role" "operator" {
  name = "nebula-terraform-operator"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow", Action = "sts:AssumeRole"
      Principal = { AWS = "arn:aws:iam::911797457485:root" }
      Condition = { ArnEquals = { "aws:PrincipalArn" = var.operator_principal_arn } }
    }]
  })
}

resource "aws_iam_role_policy" "operator" {
  name = "describe-only-this-cluster"
  role = aws_iam_role.operator.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "eks:DescribeCluster", Resource = module.eks.cluster_arn }]
  })
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.0.0"

  name                                     = local.name
  kubernetes_version                       = var.kubernetes_version
  vpc_id                                   = module.vpc.vpc_id
  subnet_ids                               = module.vpc.public_subnets
  endpoint_public_access                   = true
  endpoint_private_access                  = true
  endpoint_public_access_cidrs             = [var.cloudshell_cidr]
  authentication_mode                      = "API"
  enable_irsa                              = false
  enable_cluster_creator_admin_permissions = false
  iam_role_name                            = "nebula-terraform-cluster"
  iam_role_use_name_prefix                 = false
  enabled_log_types                        = ["audit", "api", "authenticator"]
  cloudwatch_log_group_retention_in_days   = 1
  kms_key_deletion_window_in_days          = 7
  upgrade_policy                           = { support_type = "STANDARD" }

  access_entries = {
    operator = {
      principal_arn = aws_iam_role.operator.arn
      policy_associations = {
        admin = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }

  addons = {
    vpc-cni    = { before_compute = true }
    kube-proxy = {}
    coredns    = {}
  }

  eks_managed_node_groups = {
    game = {
      name                     = "game-pool"
      use_name_prefix          = false
      min_size                 = 3
      max_size                 = 3
      desired_size             = 3
      instance_types           = ["c7i.xlarge"]
      capacity_type            = "ON_DEMAND"
      ami_type                 = "AL2023_x86_64_STANDARD"
      iam_role_name            = "nebula-terraform-nodes"
      iam_role_use_name_prefix = false
      labels                   = { rol = "juego", agones = "true" }
      block_device_mappings = {
        root = {
          device_name = "/dev/xvda"
          ebs         = { volume_size = 30, volume_type = "gp3", encrypted = true, delete_on_termination = true }
        }
      }
    }
  }

  node_security_group_additional_rules = {
    cloudshell_game = {
      description = "Nebula lab game access from current CloudShell only"
      protocol    = "tcp", from_port = 7000, to_port = 8000, type = "ingress"
      cidr_blocks = [var.cloudshell_cidr]
    }
    agones_webhook = {
      description                   = "Agones admission webhooks from EKS control plane"
      protocol                      = "tcp", from_port = 8081, to_port = 8081, type = "ingress"
      source_cluster_security_group = true
    }
  }
}
