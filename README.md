# Multi-Cluster Kind with Istio Ambient Service Mesh

A production-ready lab environment running multiple Kubernetes ([Kind](https://kind.sigs.k8s.io/)) clusters connected with **Istio Ambient Service Mesh**, **MetalLB** load balancing, and verified **cross-cluster application traffic**.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                   Docker Bridge Network                                     │
│                                   (e.g., 172.18.0.0/16)                                     │
├──────────────────────────────────────────────┬──────────────────────────────────────────────┤
│            kind-ambient-cluster1             │            kind-ambient-cluster2             │
│                                              │                                              │
│  • Node: control-plane                       │  • Node: control-plane                       │
│  • Node: worker                              │  • Node: worker                              │
│  • Pod Subnet:     10.244.0.0/16             │  • Pod Subnet:     10.245.0.0/16             │
│  • Service Subnet: 10.96.0.0/16              │  • Service Subnet: 10.97.0.0/16              │
│  • MetalLB Pool:   172.18.255.200 - 220      │  • MetalLB Pool:   172.18.255.230 - 250      │
│                                              │                                              │
│  • Istio Ambient Stack:                      │  • Istio Ambient Stack:                      │
│    ├── istiod (Control Plane)                │    ├── istiod (Control Plane)                │
│    ├── istio-cni (Traffic Redirection)       │    ├── istio-cni (Traffic Redirection)       │
│    ├── ztunnel (L4 Secure Overlay / HBONE)   │    └── ztunnel (L4 Secure Overlay / HBONE)   │
│    └── istio-ingressgateway (LoadBalancer)   │                                              │
│                                              │                                              │
│  • Namespace: ambient-demo                   │  • Namespace: ambient-demo                   │
│    (istio.io/dataplane-mode=ambient)         │    (istio.io/dataplane-mode=ambient)         │
│    ├── httpbin Deployment & Service          │    └── sleep / curl Test Client              │
│    └── Gateway & VirtualService              │                                              │
│                                              │               HTTP Request                   │
│                                              │    curl ──────────────────────────┐          │
│                                              │                                   │          │
│            ┌─────────────────────────────────┴───────────────────────────────────┘          │
│            ▼                                                                                │
│     [ Ingress Gateway (LB: 172.18.255.200) ]                                                │
│            │                                                                                │
│     [ ztunnel mTLS / HBONE ]                                                                │
│            │                                                                                │
│     [ httpbin:8000 (200 OK) ]                                                               │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 📁 Repository Structure

```
microclusters/
├── README.md                           # This documentation
├── setup-all.sh                        # One-shot master automated deployment script
├── teardown-all.sh                     # Cleanup and tear down all clusters
├── verify-cross-cluster.sh             # Cross-cluster traffic & mesh validation script
├── kind/
│   ├── kind-config-cluster1.yaml       # Cluster 1 Kind topology (CIDR: 10.244.0.0/16)
│   ├── kind-config-cluster2.yaml       # Cluster 2 Kind topology (CIDR: 10.245.0.0/16)
│   ├── multi-cluster-setup.sh          # Provisions both Kind clusters
│   ├── multi-cluster-teardown.sh       # Deletes Kind clusters
│   └── istio-1.22.0/                   # Istio distribution & local istioctl binary
├── Loadbalancer/
│   └── metallb.sh                      # MetalLB installation & dynamic IP pool configuration
├── mesh/
│   └── mesh-setup.sh                   # Istio Ambient mesh installation (ambient profile)
└── workload/
    ├── ns.yaml                         # ambient-demo namespace with ambient dataplane label
    ├── httpbin.yaml                    # httpbin Deployment & Service for cluster1
    ├── istio-ingress.yaml              # Istio Gateway & VirtualService routing to httpbin
    └── client-cluster2.yaml            # Client pod (curl/sleep) deployed in cluster2
```

---

## ⚡ Quick Start

### Prerequisites

Ensure the following tools are installed on your host machine:
- [Docker](https://docs.docker.com/get-docker/) (running with at least 4GB RAM)
- [Kind](https://kind.sigs.k8s.io/) (`brew install kind`)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/) (`brew install kubectl`)

### 1-Step Complete Provisioning

Run the master setup script:

```bash
./setup-all.sh
```

This will automatically:
1. Spin up `ambient-cluster1` and `ambient-cluster2`.
2. Install MetalLB on both clusters with dedicated IP pools matching your Docker bridge.
3. Install the Istio Ambient data plane (`istiod`, `ztunnel`, `istio-cni`, and `istio-ingressgateway`).
4. Label namespaces with `istio.io/dataplane-mode=ambient`.
5. Deploy `httpbin` on `ambient-cluster1` and the test client on `ambient-cluster2`.
6. Run the cross-cluster verification test suite.

---

## 🔍 Step-by-Step Manual Execution

If you prefer to execute the steps individually:

### Step 1: Create Kind Clusters
```bash
./kind/multi-cluster-setup.sh
```
Verifies node readiness on contexts `kind-ambient-cluster1` and `kind-ambient-cluster2`.

### Step 2: Configure MetalLB Load Balancers
```bash
./Loadbalancer/metallb.sh
```
Discovers the Kind network subnet dynamically and allocates:
- `ambient-cluster1`: `x.x.255.200 - x.x.255.220`
- `ambient-cluster2`: `x.x.255.230 - x.x.255.250`

### Step 3: Install Istio Ambient Mesh
```bash
./mesh/mesh-setup.sh
```
Installs:
- Gateway API CRDs
- Istio control plane (`istiod`)
- Istio node components: `ztunnel` DaemonSet & `istio-cni`
- `istio-ingressgateway` on `ambient-cluster1`
- `ambient-demo` namespace with Ambient mode enabled

### Step 4: Deploy Workloads
```bash
# Cluster 1: Deploy httpbin and Gateway
kubectl --context kind-ambient-cluster1 apply -f workload/httpbin.yaml
kubectl --context kind-ambient-cluster1 apply -f workload/istio-ingress.yaml

# Cluster 2: Deploy client
kubectl --context kind-ambient-cluster2 apply -f workload/client-cluster2.yaml
```

### Step 5: Verify Cross-Cluster Connectivity
```bash
./verify-cross-cluster.sh
```

---

## 🧪 Verification & Inspection

### 1. Test Cross-Cluster HTTP Call

Find the ingress gateway IP:
```bash
INGRESS_IP=$(kubectl --context kind-ambient-cluster1 -n istio-system get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Ingress IP: $INGRESS_IP"
```

Execute a request from `ambient-cluster2`:
```bash
kubectl --context kind-ambient-cluster2 -n ambient-demo exec deploy/sleep -- curl -s "http://${INGRESS_IP}/headers"
```

Expected Output:
```json
{
  "headers": {
    "Accept": "*/*",
    "Host": "172.18.255.200",
    "User-Agent": "curl/8.5.0"
  }
}
```

### 2. Inspect Istio Ambient Data Plane (ztunnel)

Verify that `ztunnel` pods are running on all nodes:
```bash
kubectl --context kind-ambient-cluster1 -n istio-system get pods -l app=ztunnel
kubectl --context kind-ambient-cluster2 -n istio-system get pods -l app=ztunnel
```

Check ztunnel connection logs:
```bash
kubectl --context kind-ambient-cluster1 -n istio-system logs -l app=ztunnel --tail=20
```

---

## 🧹 Teardown

To delete all Kind clusters and clean up resources:

```bash
./teardown-all.sh
```
