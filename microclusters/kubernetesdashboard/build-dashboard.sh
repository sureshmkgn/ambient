#!/bin/bash

KIND_CLUSTER="${KIND_CLUSTER:-ambient-cluster1}"

echo "Switching kubectl context to ${KIND_CLUSTER}..."
kubectl config use-context "${KIND_CLUSTER}"


# Step 3: Apply Kubernetes Dashboard
echo "Applying Kubernetes Dashboard manifest..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml

# Step 4: Apply admin user and cluster role binding
echo "Applying dashboard-adminuser.yaml..."
kubectl apply -f "$(dirname "$0")/dashboard-adminuser.yaml"

echo "Applying clusterrolebinding.yaml..."
kubectl apply -f "$(dirname "$0")/clusterrolebinding.yaml"

# Step 5: Start kubectl proxy
echo "Starting kubectl proxy..."
kubectl proxy &

# Step 6: Get admin user token
echo "Fetching admin user token..."
kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')

echo ""
echo "Copy the token above."
echo "Open http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/ in your browser."
echo "Select 'Token' and paste the token to log in."