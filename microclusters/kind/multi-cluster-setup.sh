#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================================="
echo "🚀 Creating Kind Multi-Cluster Environment"
echo "=================================================="

# 1. Create Cluster 1
echo "➡️  Creating cluster: ambient-cluster1..."
kind create cluster --name ambient-cluster1 --config "${SCRIPT_DIR}/kind-config-cluster1.yaml"

echo "⏳ Waiting for ambient-cluster1 nodes to be Ready..."
kubectl --context kind-ambient-cluster1 wait --for=condition=Ready node --all --timeout=120s

# 2. Create Cluster 2
echo "➡️  Creating cluster: ambient-cluster2..."
kind create cluster --name ambient-cluster2 --config "${SCRIPT_DIR}/kind-config-cluster2.yaml"

echo "⏳ Waiting for ambient-cluster2 nodes to be Ready..."
kubectl --context kind-ambient-cluster2 wait --for=condition=Ready node --all --timeout=120s

echo "=================================================="
echo "✅ Both clusters (ambient-cluster1 & ambient-cluster2) are READY!"
echo "=================================================="