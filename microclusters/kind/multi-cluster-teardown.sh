#!/usr/bin/env bash
set -eo pipefail

echo "=================================================="
echo "🧹 Tearing down Kind Clusters"
echo "=================================================="

echo "➡️  Deleting cluster: ambient-cluster1..."
kind delete cluster --name ambient-cluster1 || true

echo "➡️  Deleting cluster: ambient-cluster2..."
kind delete cluster --name ambient-cluster2 || true

echo "➡️  Deleting cluster: mgmt-cluster (if present)..."
kind delete cluster --name mgmt-cluster || true

echo "=================================================="
echo "✅ Teardown complete."
echo "=================================================="