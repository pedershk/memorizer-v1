#!/bin/bash

# Port forwarding helper script
# This script forwards all services to localhost

echo "🌐 Setting up port forwarding for Memorizer services..."
echo "Press Ctrl+C to stop all port forwards"
echo ""

# Trap SIGINT to kill all background processes
trap 'kill $(jobs -p) 2>/dev/null' EXIT SIGINT SIGTERM

# Port forward each service
kubectl port-forward -n app-memorizer svc/memorizer 5000:80 &
echo "✅ Memorizer Web UI: http://localhost:5000/ui"
echo "✅ MCP endpoint: http://localhost:5000/sse"

kubectl port-forward -n app-memorizer svc/pgadmin 5050:5050 &
echo "✅ PgAdmin: http://localhost:5050"

kubectl port-forward -n app-memorizer svc/postgres 5432:5432 &
echo "✅ PostgreSQL: localhost:5432"

kubectl port-forward -n app-memorizer svc/ollama 11434:11434 &
echo "✅ Ollama API: http://localhost:11434"

echo ""
echo "All services are now accessible on localhost"
echo "Press Ctrl+C to stop"

# Wait for all background processes
wait
