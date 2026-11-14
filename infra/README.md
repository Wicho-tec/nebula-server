# Infraestructura de Nebula Arena
Variante AWS de la práctica 3.6: VPC sin NAT, EKS con tres nodos c7i.xlarge, ECR existente importado y Agones con Helm.
Ejecuta configure.py y bootstrap_state.py desde la raíz después de autorizar el presupuesto. En esta carpeta: terraform init -backend-config=backend.hcl, terraform fmt -check, terraform validate y terraform plan -out=plan.tfplan. Revisa el plan en el PR antes de aplicar exactamente ese archivo.
No subas backend.hcl, terraform.tfvars, estados ni planes binarios. ECR tiene protección contra borrado; consulta el README principal para desvincularlo del estado antes de destruir los recursos temporales.
