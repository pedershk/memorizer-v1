#!/bin/bash
set -e

echo "🗑️  Removing Memorizer from Kubernetes..."

read -p "Are you sure you want to delete the app-memorizer namespace and all resources? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Aborted."
    exit 1
fi

echo "🧹 Deleting namespace and all resources..."
kubectl delete namespace app-memorizer

echo "✅ Cleanup complete!"
