#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

CLUSTER1="ambient-cluster1"
CLUSTER2="ambient-cluster2"

# Find or download istioctl binary
ISTIOCTL=""
if [ -f "${WORKSPACE_ROOT}/kind/istio-1.22.0/bin/istioctl" ]; then
  ISTIOCTL="${WORKSPACE_ROOT}/kind/istio-1.22.0/bin/istioctl"
elif [ -f "${WORKSPACE_ROOT}/istio-1.22.0/bin/istioctl" ]; then
  ISTIOCTL="${WORKSPACE_ROOT}/istio-1.22.0/bin/istioctl"
elif command -v istioctl &> /dev/null; then
  ISTIOCTL="istioctl"
else
  echo "📥 istioctl not found. Downloading Istio 1.22.0..."
  (cd "${WORKSPACE_ROOT}" && curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.22.0 sh -)
  ISTIOCTL="${WORKSPACE_ROOT}/istio-1.22.0/bin/istioctl"
fi

echo "=================================================="
echo "🛡️  Installing Istio Ambient Service Mesh"
echo "=================================================="
echo "ℹ️  Using istioctl: $ISTIOCTL"
"$ISTIOCTL" version --remote=false

# 1. Install Gateway API CRDs on both clusters
for CLUSTER in "$CLUSTER1" "$CLUSTER2"; do
  echo "➡️  Installing Gateway API CRDs on kind-${CLUSTER}..."
  kubectl --context "kind-${CLUSTER}" apply -f "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml"
done

# 2. Install Istio Ambient profile on Cluster 1 (with Ingress Gateway)
echo "➡️  Installing Istio Ambient Profile + Ingress Gateway on kind-${CLUSTER1}..."
"$ISTIOCTL" install --context "kind-${CLUSTER1}" \
  --set profile=ambient \
  --set "components.ingressGateways[0].name=istio-ingressgateway" \
  --set "components.ingressGateways[0].enabled=true" \
  -y

# 3. Install Istio Ambient profile on Cluster 2
echo "➡️  Installing Istio Ambient Profile on kind-${CLUSTER2}..."
"$ISTIOCTL" install --context "kind-${CLUSTER2}" \
  --set profile=ambient \
  -y

# 4. Wait for Istio components on both clusters
for CLUSTER in "$CLUSTER1" "$CLUSTER2"; do
  echo "⏳ Waiting for Istio core pods to be ready on kind-${CLUSTER}..."
  kubectl --context "kind-${CLUSTER}" -n istio-system wait --for=condition=Ready pod -l app=istiod --timeout=120s
  kubectl --context "kind-${CLUSTER}" -n istio-system wait --for=condition=Ready pod -l app=ztunnel --timeout=120s
  kubectl --context "kind-${CLUSTER}" -n istio-system wait --for=condition=Ready pod -l k8s-app=istio-cni-node --timeout=120s
done

echo "⏳ Waiting for Istio Ingress Gateway on kind-${CLUSTER1}..."
kubectl --context "kind-${CLUSTER1}" -n istio-system wait --for=condition=Ready pod -l app=istio-ingressgateway --timeout=120s

# 5. Create demo namespace with ambient dataplane enabled on both clusters
for CLUSTER in "$CLUSTER1" "$CLUSTER2"; do
  echo "➡️  Configuring 'ambient-demo' namespace with ambient dataplane mode on kind-${CLUSTER}..."
  kubectl --context "kind-${CLUSTER}" create namespace ambient-demo --dry-run=client -o yaml | kubectl --context "kind-${CLUSTER}" apply -f -
  kubectl --context "kind-${CLUSTER}" label namespace ambient-demo istio.io/dataplane-mode=ambient --overwrite
done

echo "=================================================="
echo "✅ Istio Ambient Service Mesh installed on both clusters!"
echo "=================================================="
