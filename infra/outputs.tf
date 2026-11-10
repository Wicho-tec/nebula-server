output "cluster" { value = module.eks.cluster_name }
output "registro" { value = aws_ecr_repository.nebula.repository_url }
output "vpc_id" { value = module.vpc.vpc_id }
output "operator_role" { value = aws_iam_role.operator.arn }
output "node_security_group_id" { value = module.eks.node_security_group_id }
