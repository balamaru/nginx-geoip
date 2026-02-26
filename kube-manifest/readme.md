# Kubernetes Manifests - Nginx Geo Monitoring Stack

## Structure
```
kube-manifest/
├── namespace.yaml    # monitoring namespace
├── influxdb.yaml     # InfluxDB deployment + service + PVC + secret
├── grafana.yaml      # Grafana deployment + service + PVC + secret
├── nginx.yaml        # Nginx deployment + service + configmap + PVC
└── telegraf.yaml     # Telegraf deployment + configmap
```

## Deploy Order
```bash
kubectl apply -f namespace.yaml
kubectl apply -f influxdb.yaml
kubectl apply -f nginx.yaml
kubectl apply -f telegraf.yaml
kubectl apply -f grafana.yaml
```

Or all at once:
```bash
kubectl apply -f .
```

## Important Notes

### 1. Nginx Image
The nginx container requires a custom image with the GeoIP2 module compiled in.
Build and push to your registry first:
```bash
docker build -t your-registry/nginx-geoip2:latest ./nginx
docker push your-registry/nginx-geoip2:latest
```
Then update the image field in `nginx.yaml`.

### 2. GeoIP Database Files
The `.mmdb` files (GeoLite2-Country.mmdb, GeoLite2-City.mmdb) need to be available inside the nginx pod.
Options:
- Create a ConfigMap from the binary files (if < 1MB each)
- Use an init container to download them
- Pre-bake them into the nginx Docker image (simplest)

### 3. Shared Log Volume (nginx-logs-pvc)
Both nginx and telegraf mount the same PVC (`nginx-logs-pvc`) so telegraf can read nginx logs.
Make sure your StorageClass supports `ReadWriteMany`. If not, use a hostPath or NFS-based StorageClass.

### 4. Secrets
Secrets in these manifests use `stringData` (plaintext). For production, use Sealed Secrets, Vault, or External Secrets Operator.

### 5. Accessing Services
- Grafana: `http://<node-ip>:30080` → change NodePort in grafana.yaml if needed
- Nginx: `http://<node-ip>:30080`
- InfluxDB: internal only (ClusterIP)