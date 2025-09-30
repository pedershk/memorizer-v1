# Kubernetes Deployment for Memorizer

This directory contains Kubernetes manifests and helper scripts to deploy Memorizer to a Kubernetes cluster in the `app-memorizer` namespace.

## Architecture

The deployment includes:
- **PostgreSQL** with pgvector extension (persistent storage)
- **Ollama** for embeddings and LLM (persistent storage for models)
- **Memorizer** API application (exposed via LoadBalancer on port 80)
- **PgAdmin** for database management (optional)
- **Ollama Init Job** to download required AI models

## Prerequisites

- Kubernetes cluster access with `kubectl` configured
- Sufficient cluster resources:
  - ~30GB disk space for persistent volumes (10GB PostgreSQL + 20GB Ollama)
  - ~4GB RAM minimum
  - 2+ CPU cores recommended

## Quick Start

### Deploy Everything

```bash
cd kubedeploy
./deploy.sh
```

This script will:
1. Create the `app-memorizer` namespace
2. Deploy PostgreSQL with pgvector
3. Deploy Ollama
4. Initialize Ollama models (embedding + LLM)
5. Deploy the Memorizer application
6. Deploy PgAdmin

### Access Services

The Memorizer service is exposed via an **internal LoadBalancer** with a private/VNET IP address on port 80. This is only accessible from within your virtual network for security.

After deployment completes, the script will display:
- **MCP endpoint**: `http://<PRIVATE-IP>/sse` (VNET only)
- **Admin server**: `http://<PRIVATE-IP>/ui` (VNET only)

To retrieve the URLs later:
```bash
./get-url.sh
```

**Note**: The LoadBalancer uses an internal/private IP and is NOT exposed to the internet. Access requires being within the same VNET or connected via VPN/peering.

#### Using Port Forwarding (Optional)

If you prefer local access or need to access other services:

```bash
./port-forward.sh
```

Or manually forward individual services:

```bash
# Memorizer Web UI (if not using LoadBalancer)
kubectl port-forward -n app-memorizer svc/memorizer 5000:80

# PgAdmin
kubectl port-forward -n app-memorizer svc/pgadmin 5050:5050

# PostgreSQL
kubectl port-forward -n app-memorizer svc/postgres 5432:5432

# Ollama API
kubectl port-forward -n app-memorizer svc/ollama 11434:11434
```

Then access:
- **Memorizer Web UI**: http://localhost:5000/ui
- **MCP Endpoint**: http://localhost:5000/sse
- **PgAdmin**: http://localhost:5050 (login: admin@example.com / admin)

## Manual Deployment

If you prefer to deploy components individually:

```bash
# 1. Create namespace
kubectl apply -f namespace.yaml

# 2. Deploy PostgreSQL
kubectl apply -f postgres.yaml

# 3. Deploy Ollama
kubectl apply -f ollama.yaml

# 4. Deploy Memorizer
kubectl apply -f memorizer.yaml

# 5. (Optional) Deploy PgAdmin
kubectl apply -f pgadmin.yaml
```

## Configuration

### Updating Memorizer Settings

Edit `memorizer.yaml` ConfigMap section to modify:
- Connection strings
- Embedding model
- LLM model
- Chunking parameters
- Canonical URL

Then reapply:
```bash
kubectl apply -f memorizer.yaml
kubectl rollout restart deployment/memorizer -n app-memorizer
```

### Using Different Ollama Models

Edit `ollama.yaml` Job section to change the models being pulled, then edit `memorizer.yaml` ConfigMap to reference the new model names.

### Storage Classes

The PVCs use the default storage class. To use a specific storage class:

```yaml
spec:
  storageClassName: your-storage-class
```

## Monitoring

```bash
# View all resources
kubectl get all -n app-memorizer

# View logs
kubectl logs -n app-memorizer -l app=memorizer -f
kubectl logs -n app-memorizer -l app=postgres -f
kubectl logs -n app-memorizer -l app=ollama -f

# Check Ollama init job status
kubectl logs -n app-memorizer job/ollama-init

# Describe pods for troubleshooting
kubectl describe pod -n app-memorizer -l app=memorizer
```

## Troubleshooting

### Ollama Init Job Fails

The job pulls large AI models and may timeout. Check logs:
```bash
kubectl logs -n app-memorizer job/ollama-init
```

To restart the job:
```bash
kubectl delete job ollama-init -n app-memorizer
kubectl apply -f ollama.yaml
```

### Memorizer Pod Not Starting

Check if PostgreSQL and Ollama are ready:
```bash
kubectl get pods -n app-memorizer
kubectl logs -n app-memorizer -l app=memorizer
```

### Database Connection Issues

Verify PostgreSQL is healthy:
```bash
kubectl exec -n app-memorizer deployment/postgres -- pg_isready -U postgres
```

## Cleanup

### Delete Everything

```bash
./undeploy.sh
```

Or manually:
```bash
kubectl delete namespace app-memorizer
```

Note: This will delete all data including persistent volumes.

### Keep Data, Remove Applications

```bash
kubectl delete deployment --all -n app-memorizer
kubectl delete service --all -n app-memorizer
kubectl delete job --all -n app-memorizer
```

This preserves PVCs for later use.

## Production Considerations

For production deployments, consider:

1. **Security**:
   - Use Kubernetes Secrets instead of ConfigMaps for passwords
   - Enable TLS/SSL for PostgreSQL connections
   - Use network policies to restrict inter-pod communication
   - Change default passwords

2. **High Availability**:
   - Use PostgreSQL with replication (StatefulSet)
   - Increase Memorizer replicas
   - Configure pod anti-affinity

3. **Resource Limits**:
   - Adjust resource requests/limits based on workload
   - Configure horizontal pod autoscaling

4. **Storage**:
   - Use production-grade storage classes
   - Configure backup strategies for PVCs
   - Consider using managed PostgreSQL service

5. **Ingress**:
   - Set up Ingress controller for external access
   - Configure proper DNS and TLS certificates

Example Ingress:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: memorizer-ingress
  namespace: app-memorizer
spec:
  rules:
  - host: memorizer.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: memorizer
            port:
              number: 5000
```

## Files

- `namespace.yaml` - Namespace definition
- `postgres.yaml` - PostgreSQL with pgvector deployment
- `ollama.yaml` - Ollama deployment and init job
- `memorizer.yaml` - Memorizer application deployment (LoadBalancer)
- `pgadmin.yaml` - PgAdmin deployment (optional)
- `deploy.sh` - Automated deployment script
- `undeploy.sh` - Cleanup script
- `get-url.sh` - Display LoadBalancer IP and access URLs
- `port-forward.sh` - Helper to forward all service ports
