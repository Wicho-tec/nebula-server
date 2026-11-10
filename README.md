# Práctica 3.6 - Nebula Arena con Terraform, variante AWS

## Estado

Preparación local. No se han creado recursos AWS de 3.6. Terraform 1.13.5 oficial descargado con SHA256 verificado; módulos/proveedores firmados inicializados con backend desactivado. `terraform validate` pasó y `terraform fmt -check` pasó. El plan real, su revisión en PR, apply, captura y destroy están pendientes de autorización de costo/acceso. La validación no prueba un despliegue real.

El clúster manual de 3.3/3.4 ya fue eliminado. La 3.5 usa Lambda y DynamoDB independientes; no requiere conservar el clúster nuevo. Se conservará ECR nebula-server para evitar romper el entregable CI/CD anterior.

## Recursos y permisos propuestos

- Cuenta 911797457485, us-east-1, workspace default: clúster EKS `nebula-default`, Kubernetes 1.35 con soporte estándar. VPC `10.36.0.0/16`, dos subredes públicas, sin NAT Gateway ni balanceadores. Los nodos usan IPv4 pública para salida a AWS; SSH no se abre.
- Módulos oficiales `terraform-aws-modules/vpc/aws` 6.0.1 y `terraform-aws-modules/eks/aws` 21.0.0. Tres nodos c7i.xlarge ON_DEMAND, min=desired=max=3, discos gp3 cifrados de 30 GB, borrado al terminar. No Auto Mode, Fargate ni IRSA.
- Rol `nebula-terraform-cluster`: confianza EKS y políticas de servicio del módulo. Rol `nebula-terraform-nodes`: confianza EC2, políticas de nodo EKS, CNI y lectura de ECR. Los roles son temporales y se destruyen con el clúster.
- Rol `nebula-terraform-operator`: solo la identidad IAM existente que ejecuta la práctica puede asumirlo (condición aws:PrincipalArn exacta). En AWS solo DescribeCluster del clúster nuevo. Una entrada EKS le concede administración de ese clúster para Helm/kubectl. No se crean claves permanentes ni se concede administración de la cuenta AWS.
- API pública EKS y juego TCP 7000-8000 únicamente desde la IPv4 /32 actual de CloudShell; API privada para comunicación interna y reglas del control plane para webhooks Agones. Si cambia la IP, se revisa el cambio en plan antes de actualizarla.
- Clave KMS propia del módulo para secretos EKS; acceso del servicio del clúster y propietario existente de la cuenta. Se programará su borrado con espera mínima de siete días al hacer destroy. AWS no cobra almacenamiento de claves pendientes de borrado; no significa borrado inmediato.
- Bucket de backend `nebula-tfstate-911797457485-us-east-1`, privado, bloqueo público completo, SSE-S3 AES256, versiones y denegación de transporte sin TLS. Bloqueo nativo S3 `use_lockfile=true`; no tabla DynamoDB adicional. Estado y variables no se suben a Git.
- Importar ECR `nebula-server`, sin modificar configuración ni imágenes; prevent_destroy e ignore_changes=all. Antes del destroy se retirará del estado mediante bloque nativo removed con destroy=false. No se eliminará el repositorio previo ni su rol GitHub.
- Agones 1.62 con Helm, allocator ClusterIP, una réplica del controlador. La flota usa la imagen inmutable de 3.2 y la corrección /ready de 3.4 montada en ConfigMap de solo lectura; no se presenta como una imagen reconstruida. Etiqueta de nodos `rol=juego`.

## Presupuesto que requiere autorización

Objetivo adicional de **1.50 USD en créditos**, sin garantía de gratuidad y sin tope automático de AWS. Estimación de cómputo y soporte por hora:

- 3 × c7i.xlarge × 0.1785 = 0.5355 USD/h.
- EKS estándar = 0.10 USD/h.
- 3 IPv4 × 0.005 = 0.015 USD/h.
- 90 GB gp3 × 0.08 / 730 = 0.00986 USD/h.
- Clave KMS de 1 USD/mes prorrateada: aproximadamente 0.00137 USD/h, más llamadas.
- Base aproximada: 0.662 USD/h. Para 30-90 minutos, aproximadamente 0.33-0.99 USD, más cantidades pequeñas por logs, S3, requests y tráfico. Margen hasta 1.50 USD. Actualizar tarifas y revisar plan antes de apply; no ampliar nodos ni hacer otra prueba de carga de 3.4.

Configurar una acción nativa de ASG para llevar nodos a cero como máximo 60 minutos después de que estén disponibles. Es respaldo de apagado, no tope financiero: EKS sigue cobrando hasta su eliminación. Tras confirmar la captura, ejecutar limpieza completa sin dejar el clúster esperando otra sesión. Mantener únicamente ECR previo y el bucket de estado versionado como evidencia identificada; el almacenamiento pequeño del backend puede generar fracciones de centavo al mes. Su eliminación definitiva se trata aparte al terminar la entrega.

Fuentes: tarifas AWS Pricing API conservadas en 3.4/evidencias/budget-review.json; https://aws.amazon.com/eks/pricing/ ; https://aws.amazon.com/vpc/pricing/ ; https://aws.amazon.com/ebs/pricing/ ; https://aws.amazon.com/kms/pricing/ . La cifra anterior es un modelo, no saldo ni factura de la cuenta.

## Ejecución después de autorización

1. Comprobar STS/cuenta, cuota EC2 y ausencia del clúster/roles nuevos; preservar recursos previos. Ejecutar `configure.py` en CloudShell, revisar tfvars ignorado y obtener versiones EKS/addons vigentes. No imprimir credenciales.
2. Crear backend con `bootstrap_state.py`, una sola vez. En infra: `terraform init -backend-config=backend.hcl`; incluir `.terraform.lock.hcl` en Git.
3. `terraform fmt -check`; `terraform validate`; `terraform plan -out=plan.tfplan`; `terraform show -no-color plan.tfplan` a evidencia de texto. Revisar el JSON sin publicarlo: cuenta/región, tres c7i.xlarge, discos gp3, /32, sin NAT/LB/Fargate y sin cambios destructivos en recursos previos. El resumen de texto debe omitir la IP personal y datos sensibles antes de subirlo al repositorio privado.
4. Crear rama y pull request en Wicho-tec/nebula-server con carpeta infra/, k8s/, documentación y el plan de texto sanitizado. Registrar revisión propia, sin simular aprobación de otra persona. Aplicar solo el archivo plan revisado: `terraform apply plan.tfplan`. No fusionar automáticamente ni ejecutar el workflow de main por cambios de infraestructura.
5. Configurar kubectl con el rol operator. Programar el respaldo ASG con los identificadores verificados de este nodegroup. Crear ConfigMap desde k8s/server.py y aplicar fleet.yaml/autoscaler.yaml. Verificar tres nodos Ready, Agones saludable, flota Ready y asignación de un GameServer. Mostrar salida y pausar para captura del usuario.
6. Quitar la flota y liberar partidas de prueba. Para preservar ECR: renombrar temporalmente infra/ecr.tf a ecr.tf.retained; usar un archivo removed.tf con `removed { from = aws_ecr_repository.nebula lifecycle { destroy = false } }`. Revisar/aplicar un plan de desvinculación que solo retire ECR del estado; no borre AWS ni cambie otros recursos. Conservar fuente original en Git.
7. `terraform plan -destroy -out=destroy.tfplan`; revisar y `terraform apply destroy.tfplan`. Debe retirar Helm, EKS, nodos, discos, red, roles y programar KMS para borrado. Verificar APIs AWS y estado; mostrar evidencia de destroy para captura. ECR previo y backend son retenciones intencionales, no recursos de cómputo huérfanos.

Terraform no garantiza crear EKS en 15 minutos; se medirá la duración real. Si un paso falla, conservar logs, retirar cómputo ya creado y corregir sin ampliar presupuesto automáticamente.

## Validaciones locales

En Windows, el Git del escritorio estaba incompleto. Para init se usó el Git incluido en Codex, solo cambiando PATH/GIT_EXEC_PATH del proceso. Terraform validate requiere permitir comunicación local entre CLI y plugins. No se configuraron credenciales AWS locales y el backend estuvo desactivado.

Comandos verificados: `tools/terraform.exe fmt -check -recursive infra`; desde infra, `../tools/terraform.exe init -backend=false` y `../tools/terraform.exe validate`. Plan/apply y pruebas Kubernetes todavía no ejecutados.
