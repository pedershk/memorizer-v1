#!/bin/bash

# Get LoadBalancer IP and display access URLs

MEMORIZER_IP=$(kubectl get svc memorizer -n app-memorizer -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

if [ -z "$MEMORIZER_IP" ]; then
  # Try hostname field (some cloud providers use this instead of IP)
  MEMORIZER_IP=$(kubectl get svc memorizer -n app-memorizer -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
fi

if [ -z "$MEMORIZER_IP" ]; then
  echo "⚠️  LoadBalancer IP not yet assigned"
  echo ""
  kubectl get svc memorizer -n app-memorizer
  echo ""
  echo "Wait for EXTERNAL-IP to be assigned, then run this script again."
  exit 1
fi

echo "✅ Memorizer Internal LoadBalancer IP: $MEMORIZER_IP (private/VNET only)"
echo ""
echo "🌐 Access your Memorizer instance (from within the VNET):"
echo ""
echo "   📡 MCP endpoint:  http://$MEMORIZER_IP/sse"
echo "   🖥️  Admin server:  http://$MEMORIZER_IP/ui"
echo ""
