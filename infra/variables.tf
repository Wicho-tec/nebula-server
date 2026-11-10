variable "cloudshell_cidr" {
  description = "Current CloudShell public IPv4 /32; discover before plan, never commit the tfvars file."
  type        = string
  validation {
    condition     = can(cidrhost(var.cloudshell_cidr, 0)) && endswith(var.cloudshell_cidr, "/32")
    error_message = "Provide a single IPv4 /32 for CloudShell."
  }
}

variable "operator_principal_arn" {
  description = "Existing IAM user/root that runs this lab; assumed sessions must use their source IAM role ARN."
  type        = string
  validation {
    condition     = can(regex("^arn:aws:iam::911797457485:(root|user/.+|role/.+)$", var.operator_principal_arn))
    error_message = "Only an existing principal in the approved account is accepted."
  }
}

variable "kubernetes_version" {
  type    = string
  default = "1.35"
}
