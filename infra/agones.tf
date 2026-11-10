provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = ["eks", "get-token", "--region", "us-east-1", "--cluster-name", local.name,
      "--role-arn", aws_iam_role.operator.arn]
    }
  }
}

resource "helm_release" "agones" {
  name             = "agones"
  repository       = "https://agones.dev/chart/stable"
  chart            = "agones"
  version          = "1.62.0"
  namespace        = "agones-system"
  create_namespace = true
  wait             = true
  timeout          = 600
  values = [yamlencode({
    agones = {
      featureGates = "PlayerTracking=true"
      allocator    = { service = { type = "ClusterIP" } }
      controller   = { replicas = 1 }
    }
  })]
  depends_on = [module.eks, aws_iam_role_policy.operator]
}
