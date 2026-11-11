# Flota de prueba

Con el contexto del clúster nebula-default, crea el ConfigMap desde k8s/server.py y aplica fleet.yaml y autoscaler.yaml.

```sh
kubectl create configmap nebula-server-startup --from-file=server.py=k8s/server.py --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f k8s/fleet.yaml -f k8s/autoscaler.yaml
kubectl get nodes,gs
```
