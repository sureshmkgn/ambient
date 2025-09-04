echo "Creating kind cluster ambient-cluster1..."

SCRIPT_DIR="$(dirname "$0")"

kind create cluster --name ambient-cluster1 --config "${SCRIPT_DIR}/kind-config-cluster1.yaml"

# Wait for the cluster to be ready
echo "Waiting for cluster nodes to be ready..."
kubectl wait --for=condition=Ready node --all --timeout=120s

# Apply Calico CNI
echo "Applying Calico CNI..."
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Wait for Calico pods to be ready
echo "Waiting for Calico pods to be ready..."
kubectl -n kube-system wait --for=condition=Ready pod -l k8s-app=calico-node --timeout=30s


kind create cluster --name ambient-cluster2 --config "${SCRIPT_DIR}/kind-config-cluster2.yaml"

echo "Waiting for cluster nodes to be ready..."
kubectl --context kind-ambient-cluster2 wait --for=condition=Ready node --all --timeout=120s

echo "Applying Calico CNI to ambient-cluster2..."
kubectl --context kind-ambient-cluster2 apply -f https://docs.projectcalico.org/manifests/calico.yaml

echo "Waiting for Calico pods to be ready in ambient-cluster2..."
kubectl --context kind-ambient-cluster2 -n kube-system wait --for=condition=Ready pod -l k8s-app=calico-node --timeout=30s


# Create a management cluster
echo "Creating kind management cluster mgmt-cluster..."
kind create cluster --name mgmt-cluster --config "${SCRIPT_DIR}/kind-config-mgmt.yaml"

echo "Waiting for cluster nodes to be ready..."
kubectl --context kind-mgmt-cluster wait --for=condition=Ready node --all --timeout=120s

echo "Applying Calico CNI to mgmt-cluster..."
kubectl --context kind-mgmt-cluster apply -f https://docs.projectcalico.org/manifests/calico.yaml

echo "Waiting for Calico pods to be ready in mgmt-cluster..."
kubectl --context kind-mgmt-cluster -n kube-system wait --for=condition=Ready pod -l k8s-app=calico-node --timeout=30s