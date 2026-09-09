#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================================================"
echo "🌟 STARTING MULTI-CLUSTER KIND & ISTIO AMBIENT MESH SETUP"
echo "================================================================"

# Step 1: Provision Kind Clusters
echo ""
echo "=== STEP 1: Provisioning Kind Clusters ==="
bash "${SCRIPT_DIR}/kind/multi-cluster-setup.sh"

# Step 2: Install and Configure MetalLB Load Balancers
echo ""
echo "=== STEP 2: Installing MetalLB Load Balancers ==="
bash "${SCRIPT_DIR}/Loadbalancer/metallb.sh"

# Step 3: Install Istio Ambient Mesh
echo ""
echo "=== STEP 3: Installing Istio Ambient Mesh ==="
bash "${SCRIPT_DIR}/mesh/mesh-setup.sh"

# Step 4: Deploy Workloads
echo ""
echo "=== STEP 4: Deploying Workloads ==="
echo "➡️  Deploying httpbin + Ingress Gateway on kind-ambient-cluster1..."
kubectl --context kind-ambient-cluster1 apply -f "${SCRIPT_DIR}/workload/httpbin.yaml"
kubectl --context kind-ambient-cluster1 apply -f "${SCRIPT_DIR}/workload/istio-ingress.yaml"

echo "➡️  Deploying test client (sleep/curl) on kind-ambient-cluster2..."
kubectl --context kind-ambient-cluster2 apply -f "${SCRIPT_DIR}/workload/client-cluster2.yaml"

echo "⏳ Waiting for httpbin on kind-ambient-cluster1..."
kubectl --context kind-ambient-cluster1 -n ambient-demo wait --for=condition=Available deployment/httpbin --timeout=120s

echo "⏳ Waiting for client on kind-ambient-cluster2..."
kubectl --context kind-ambient-cluster2 -n ambient-demo wait --for=condition=Available deployment/sleep --timeout=120s

echo ""
echo "================================================================"
echo "🎉 ALL COMPONENTS DEPLOYED! RUNNING VERIFICATION..."
echo "================================================================"
bash "${SCRIPT_DIR}/verify-cross-cluster.sh"
