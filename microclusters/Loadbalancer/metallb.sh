#!/usr/bin/env bash
set -euo pipefail

METALLB_VERSION="v0.14.8"
CLUSTER1="ambient-cluster1"
CLUSTER2="ambient-cluster2"

echo "=================================================="
echo "🌐 Installing MetalLB Load Balancers"
echo "=================================================="

# 1. Install MetalLB on both clusters
for CLUSTER in "$CLUSTER1" "$CLUSTER2"; do
  echo "➡️  Installing MetalLB on kind-${CLUSTER}..."
  kubectl --context "kind-${CLUSTER}" apply -f "https://raw.githubusercontent.com/metallb/metallb/${METALLB_VERSION}/config/manifests/metallb-native.yaml"
done

# 2. Wait for MetalLB pods to be ready
for CLUSTER in "$CLUSTER1" "$CLUSTER2"; do
  echo "⏳ Waiting for MetalLB controller & speaker on kind-${CLUSTER}..."
  kubectl --context "kind-${CLUSTER}" -n metallb-system wait --for=condition=Available deployment/controller --timeout=120s
  kubectl --context "kind-${CLUSTER}" -n metallb-system wait --for=condition=Ready pod -l component=speaker --timeout=120s
done

# 3. Determine Kind network IP range
KIND_SUBNET=$(docker network inspect kind -f '{{(index .IPAM.Config 0).Subnet}}')
echo "ℹ️  Kind network subnet detected: ${KIND_SUBNET}"

# Extract base prefix (e.g., 172.18 from 172.18.0.0/16)
BASE_IP=$(echo "$KIND_SUBNET" | cut -d'.' -f1,2)

# Pool for cluster 1
C1_START="${BASE_IP}.255.200"
C1_END="${BASE_IP}.255.220"

# Pool for cluster 2
C2_START="${BASE_IP}.255.230"
C2_END="${BASE_IP}.255.250"

echo "➡️  Configuring IPAddressPool [${C1_START} - ${C1_END}] for kind-${CLUSTER1}..."
cat <<EOF | kubectl --context "kind-${CLUSTER1}" apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: cluster1-pool
  namespace: metallb-system
spec:
  addresses:
  - ${C1_START}-${C1_END}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: cluster1-l2
  namespace: metallb-system
EOF

echo "➡️  Configuring IPAddressPool [${C2_START} - ${C2_END}] for kind-${CLUSTER2}..."
cat <<EOF | kubectl --context "kind-${CLUSTER2}" apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: cluster2-pool
  namespace: metallb-system
spec:
  addresses:
  - ${C2_START}-${C2_END}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: cluster2-l2
  namespace: metallb-system
EOF

echo "=================================================="
echo "✅ MetalLB successfully installed & configured on both clusters!"
echo "=================================================="