#!/usr/bin/env bash
set -euo pipefail

echo "================================================================"
echo "🧪 CROSS-CLUSTER CONNECTIVITY & ISTIO AMBIENT VERIFICATION"
echo "================================================================"

echo "🔍 Fetching Ingress Gateway LoadBalancer IP on kind-ambient-cluster1..."
INGRESS_IP=""
for i in {1..30}; do
  INGRESS_IP=$(kubectl --context kind-ambient-cluster1 -n istio-system get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
  if [ -n "$INGRESS_IP" ]; then
    break
  fi
  echo "Waiting for LoadBalancer IP allocation... ($i/30)"
  sleep 2
done

if [ -z "$INGRESS_IP" ]; then
  echo "❌ Error: Ingress Gateway LoadBalancer IP was not assigned!"
  exit 1
fi

echo "✅ Cluster 1 Ingress Gateway IP: ${INGRESS_IP}"

echo ""
echo "🚀 Sending cross-cluster HTTP request from kind-ambient-cluster2 (sleep pod) -> kind-ambient-cluster1 (httpbin)..."

HTTP_STATUS=$(kubectl --context kind-ambient-cluster2 -n ambient-demo exec deploy/sleep -- curl -s -o /dev/null -w "%{http_code}" "http://${INGRESS_IP}/headers")

if [ "$HTTP_STATUS" -eq 200 ]; then
  echo "✅ Success! Received HTTP status: ${HTTP_STATUS}"
else
  echo "❌ Failed! Received HTTP status: ${HTTP_STATUS}"
  exit 1
fi

echo ""
echo "📄 Response Payload (from http://${INGRESS_IP}/headers via ambient-cluster2):"
kubectl --context kind-ambient-cluster2 -n ambient-demo exec deploy/sleep -- curl -s "http://${INGRESS_IP}/headers"

echo ""
echo "📄 Testing /ip endpoint:"
kubectl --context kind-ambient-cluster2 -n ambient-demo exec deploy/sleep -- curl -s "http://${INGRESS_IP}/ip"

echo ""
echo "🛡️  Checking ztunnel data plane logs on kind-ambient-cluster1 (last 5 lines):"
kubectl --context kind-ambient-cluster1 -n istio-system logs -l app=ztunnel --tail=5 || true

echo ""
echo "================================================================"
echo "🎯 CROSS-CLUSTER AMBIENT MESH VERIFICATION PASSED!"
echo "================================================================"
