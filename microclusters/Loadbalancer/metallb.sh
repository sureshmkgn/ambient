#!/bin/bash

# Configurable cluster names
CLUSTER1="${CLUSTER1:-ambient-cluster1}"
CLUSTER2="${CLUSTER2:-ambient-cluster2}"

# Apply MetalLB to cluster1
echo "Switching to context kind-${CLUSTER1} and installing MetalLB..."
kubectl config use-context kind-${CLUSTER1}
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.10/config/manifests/metallb-native.yaml

# Apply MetalLB to cluster2
echo "Switching to context kind-${CLUSTER2} and installing MetalLB..."
kubectl config use-context kind-${CLUSTER2}
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.10/config/manifests/metallb-native.yaml

echo "MetalLB installed on both clusters."