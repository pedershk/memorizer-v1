#!/bin/bash
set -e

echo "🚀 Deploying Memorizer to Kubernetes..."

# Create namespace
echo "📦 Creating namespace..."
kubectl apply -f namespace.yaml

# Deploy PostgreSQL
echo "🐘 Deploying PostgreSQL..."
kubectl apply -f postgres.yaml

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n app-memorizer --timeout=300s

# Deploy Ollama
echo "🤖 Deploying Ollama..."
kubectl apply -f ollama.yaml

# Wait for Ollama to be ready
echo "⏳ Waiting for Ollama to be ready..."
kubectl wait --for=condition=ready pod -l app=ollama -n app-memorizer --timeout=300s

# Initialize Ollama models (run job)
echo "📥 Initializing Ollama models (this may take a few minutes)..."
kubectl delete job ollama-init -n app-memorizer --ignore-not-found=true
kubectl apply -f ollama.yaml
kubectl wait --for=condition=complete job/ollama-init -n app-memorizer --timeout=600s

# Deploy Memorizer
echo "🧠 Deploying Memorizer application..."
kubectl apply -f memorizer.yaml

# Wait for Memorizer to be ready
echo "⏳ Waiting for Memorizer to be ready..."
kubectl wait --for=condition=ready pod -l app=memorizer -n app-memorizer --timeout=300s

# Deploy PgAdmin (optional)
echo "🔧 Deploying PgAdmin..."
kubectl apply -f pgadmin.yaml

echo "✅ Deployment complete!"
echo ""
echo "📊 Checking deployment status..."
kubectl get all -n app-memorizer

echo ""
echo "⏳ Waiting for internal LoadBalancer to get a private IP..."
echo "   (This may take 1-2 minutes depending on your cloud provider)"

# Wait for LoadBalancer IP (with timeout)
TIMEOUT=180
ELAPSED=0
MEMORIZER_IP=""

while [ $ELAPSED -lt $TIMEOUT ]; do
  MEMORIZER_IP=$(kubectl get svc memorizer -n app-memorizer -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

  if [ -z "$MEMORIZER_IP" ]; then
    # Try hostname field (some cloud providers use this instead of IP)
    MEMORIZER_IP=$(kubectl get svc memorizer -n app-memorizer -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
  fi

  if [ -n "$MEMORIZER_IP" ]; then
    break
  fi

  sleep 5
  ELAPSED=$((ELAPSED + 5))
  echo -n "."
done

echo ""

if [ -z "$MEMORIZER_IP" ]; then
  echo "⚠️  Warning: LoadBalancer IP not assigned yet. Check status with:"
  echo "   kubectl get svc memorizer -n app-memorizer"
  echo ""
  echo "🌐 Once the EXTERNAL-IP is assigned, you can access (from within the VNET):"
  echo "   MCP endpoint: http://<PRIVATE-IP>/sse"
  echo "   Admin server: http://<PRIVATE-IP>/ui"
else
  echo "✅ Internal LoadBalancer IP assigned: $MEMORIZER_IP (private/VNET only)"
  echo ""
  echo "🌐 Access your Memorizer instance (from within the VNET):"
  echo ""
  echo "   📡 MCP endpoint:  http://$MEMORIZER_IP/sse"
  echo "   🖥️  Admin server:  http://$MEMORIZER_IP/ui"
  echo ""
fi

echo "🔧 Additional services (use port-forwarding):"
echo "   PgAdmin: kubectl port-forward -n app-memorizer svc/pgadmin 5050:5050"
echo "   PostgreSQL: kubectl port-forward -n app-memorizer svc/postgres 5432:5432"
echo ""
echo "🔍 To view logs:"
echo "   kubectl logs -n app-memorizer -l app=memorizer -f"
echo ""
echo "🗑️  To delete everything:"
echo "   ./undeploy.sh"
