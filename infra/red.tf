module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.1"

  name                    = local.name
  cidr                    = "10.36.0.0/16"
  azs                     = local.azs
  public_subnets          = ["10.36.1.0/24", "10.36.2.0/24"]
  map_public_ip_on_launch = true
  enable_nat_gateway      = false
  enable_dns_hostnames    = true
  enable_dns_support      = true
  public_subnet_tags      = { "kubernetes.io/role/elb" = "1" }
}
