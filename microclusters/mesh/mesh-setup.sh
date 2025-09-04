CLUSTER1="${CLUSTER1:-cluster1}"
CLUSTER2="${CLUSTER2:-cluster2}"

# Download Istioctl (Ambient Mesh is part of Istio)
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.22.0 sh -

export PATH="$PATH:$(pwd)/istio-1.22.0/bin"

# Install Istio with Ambient Mesh profile on ${CLUSTER1}
echo "Installing Ambient Mesh on ${CLUSTER1}..."
istioctl install --context kind-${CLUSTER1} --set profile=ambient -y

# Install Istio with Ambient Mesh profile on ${CLUSTER2}
echo "Installing Ambient Mesh on ${CLUSTER2}..."
istioctl install --context kind-${CLUSTER2} --set profile=ambient -y

echo "Ambient Mesh installation complete on both clusters."

