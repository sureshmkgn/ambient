#!/bin/bash

# Configurable cluster names
MGMT_CLUSTER="${MGMT_CLUSTER:-mgmt-cluster}"
CLUSTER1="${CLUSTER1:-ambient-cluster1}"
CLUSTER2="${CLUSTER2:-ambient-cluster2}"

# Create a new Kind management cluster
echo "Creating Kind management cluster: ${MGMT_CLUSTER}..."
kind create cluster --name "${MGMT_CLUSTER}" --config "$(dirname "$0")/kind-config-mgmt.yaml"

echo "Waiting for management cluster nodes to be ready..."
kubectl --context kind-${MGMT_CLUSTER} wait --for=condition=Ready node --all --timeout=60s

# Install Gloo Mesh CRDs and core components in the management cluster
echo "Installing Gloo Mesh in ${MGMT_CLUSTER}..."
kubectl --context kind-${MGMT_CLUSTER} apply -f https://github.com/solo-io/gloo-mesh/releases/latest/download/gloo-mesh-crds.yaml
kubectl --context kind-${MGMT_CLUSTER} apply -f https://github.com/solo-io/gloo-mesh/releases/latest/download/gloo-mesh.yaml

echo "Waiting for Gloo Mesh pods to be ready in ${MGMT_CLUSTER}..."
kubectl --context kind-${MGMT_CLUSTER} -n gloo-mesh wait --for=condition=Ready pod --all --timeout=180s

# Register existing clusters with Gloo Mesh
echo "Registering ${CLUSTER1} with Gloo Mesh..."
gloo mesh cluster register --name ${CLUSTER1} --kubecontext kind-${CLUSTER1} --mgmt-context kind-${MGMT_CLUSTER}

echo "Registering ${CLUSTER2} with Gloo Mesh..."
gloo mesh cluster register --name ${CLUSTER2} --kubecontext kind-${CLUSTER2} --mgmt-context kind-${MGMT_CLUSTER}

echo "Both clusters registered with Gloo Mesh."

# Deploy Gloo Mesh UI in the management cluster
echo "Deploying Gloo Mesh UI in ${MGMT_CLUSTER}..."
kubectl --context kind-${MGMT_CLUSTER} apply -f https://github.com/solo-io/gloo-mesh-ui/releases/latest/download/gloo-mesh-ui.yaml

# Port-forward Gloo Mesh UI service
echo "Port-forwarding Gloo Mesh UI service on ${MGMT_CLUSTER}..."
kubectl --context kind-${MGMT_CLUSTER} -n gloo-mesh port-forward svc/gloo-mesh-ui 8090:8090 &

echo "Gloo Mesh UI is available at http://localhost:8090"