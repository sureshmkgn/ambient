echo "Deleting ambient-cluster1..."
kind delete cluster --name ambient-cluster1

echo "Deleting ambient-cluster2..."
kind delete cluster --name ambient-cluster2

echo "Kind clusters cleanup complete."

echo "Deleting mgmt-cluster..."
kind delete cluster --name mgmt-cluster