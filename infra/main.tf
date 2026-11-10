terraform {
  required_version = ">= 1.10, < 2.0"
  required_providers {
    aws  = { source = "hashicorp/aws", version = "~> 6.0" }
    helm = { source = "hashicorp/helm", version = "~> 3.0" }
  }
  backend "s3" {}
}

provider "aws" {
  region              = "us-east-1"
  allowed_account_ids = ["911797457485"]
  default_tags { tags = { practica = "3.6", project = "nebula", managed_by = "terraform" } }
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" { state = "available" }

locals {
  name = "nebula-${terraform.workspace}"
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)
}
