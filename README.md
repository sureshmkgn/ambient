# Multi-Cluster Kind with Istio Ambient Service Mesh

[![Kubernetes](https://img.shields.io/badge/Kubernetes-Kind-326CE5?style=flat-square&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Istio Ambient](https://img.shields.io/badge/Istio-Ambient%20Mesh-466BB0?style=flat-square&logo=istio&logoColor=white)](https://istio.io/latest/docs/ambient/)
[![MetalLB](https://img.shields.io/badge/LoadBalancer-MetalLB-009688?style=flat-square)](https://metallb.universe.tf/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

> **Automated, sidecarless multi-cluster service mesh laboratory powered by Kubernetes (Kind), Istio Ambient mode, MetalLB, and cross-cluster L4/L7 service routing.**

---

## 📖 Overview

This repository provides a fully automated, reproducible environment to stand up **multi-cluster Kubernetes environments locally** using [Kind](https://kind.sigs.k8s.io/) and configure **Istio Ambient Service Mesh** across clusters. 

### Why Ambient Mesh?
Traditional service meshes require injecting an Envoy sidecar proxy into every application pod, introducing memory overhead, CPU consumption, and lifecycle management complexities. **Istio Ambient Mesh** splits the data plane into two distinct layers:
1. **Secure L4 Overlay Layer (`ztunnel`)**: Runs as a lightweight node daemonset to handle mTLS encryption, authentication, and telemetry transparently without sidecars.
2. **Optional L7 Processing Layer (`waypoint proxies` & `ingress gateways`)**: Deployed only when advanced traffic routing, security policies, or header transformations are needed.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                   Docker Bridge Network                                     │
│                                   (e.g., 172.19.0.0/16)                                     │
├──────────────────────────────────────────────┬──────────────────────────────────────────────┤
│            kind-ambient-cluster1             │            kind-ambient-cluster2             │
│                                              │                                              │
│  • Node: control-plane                       │  • Node: control-plane                       │
│  • Node: worker                              │  • Node: worker                              │
│  • Pod Subnet:     10.244.0.0/16             │  • Pod Subnet:     10.245.0.0/16             │
│  • Service Subnet: 10.96.0.0/16              │  • Service Subnet: 10.97.0.0/16              │
│  • MetalLB Pool:   172.19.255.200 - 220      │  • MetalLB Pool:   172.19.255.230 - 250      │
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
│     [ Ingress Gateway (LB: 172.19.255.200) ]                                                │
│            │                                                                                │
│     [ ztunnel mTLS / HBONE ]                                                                │
│            │                                                                                │
│     [ httpbin:8000 (200 OK) ]                                                               │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## ✨ Features

- 🚀 **1-Command Full Stack Provisioning**: Brings up Kind clusters, MetalLB, Istio Ambient mesh, and sample workloads with a single script (`./setup-all.sh`).
- ⚡ **Sidecarless Data Plane**: Employs Istio's ambient architecture with `ztunnel` and `istio-cni` for zero-pod-modification mTLS and telemetry.
- 🌐 **Dynamic MetalLB IP Allocation**: Automatically discovers Docker bridge subnets and creates isolated `IPAddressPool`s for each cluster.
- 🧪 **Automated Cross-Cluster Verification**: Includes test suite (`./verify-cross-cluster.sh`) testing cross-cluster communication from Cluster 2 to `httpbin` on Cluster 1.
- 🧹 **Clean Teardown**: Fast cleanup script (`./teardown-all.sh`) ensuring no leftover Docker containers or bridge networks.

---

## 📁 Repository Structure

```
.
├── README.md                           # Project documentation
├── microclusters/
│   ├── README.md                       # Microclusters guide
│   ├── setup-all.sh                    # Master deployment script
│   ├── teardown-all.sh                 # Cluster teardown script
│   ├── verify-cross-cluster.sh         # End-to-end verification script
│   ├── kind/
│   │   ├── kind-config-cluster1.yaml   # Topology for cluster1 (CIDR: 10.244.0.0/16)
│   │   ├── kind-config-cluster2.yaml   # Topology for cluster2 (CIDR: 10.245.0.0/16)
│   │   ├── multi-cluster-setup.sh      # Provisions both Kind clusters
│   │   └── multi-cluster-teardown.sh   # Tears down Kind clusters
│   ├── Loadbalancer/
│   │   └── metallb.sh                  # MetalLB deployment & pool config
│   ├── mesh/
│   │   └── mesh-setup.sh               # Istio Ambient mesh installer
│   └── workload/
│       ├── ns.yaml                     # ambient-demo namespace definition
│       ├── httpbin.yaml                # Target httpbin application
│       ├── istio-ingress.yaml          # Gateway and VirtualService
│       └── client-cluster2.yaml        # Curl/sleep client on cluster2
```

---

## ⚡ Quick Start

### Prerequisites
- [Docker](https://docs.docker.com/get-docker/) (running with at least 4GB RAM allocated)
- [Kind](https://kind.sigs.k8s.io/) (`brew install kind`)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/) (`brew install kubectl`)

### Run All-In-One Setup

```bash
cd microclusters
./setup-all.sh
```

The script will automatically provision clusters, configure MetalLB, install Istio Ambient mode, deploy workloads, and run cross-cluster verification.

---

## 🔍 Step-by-Step Manual Execution

```bash
cd microclusters

# Step 1: Create Kind Clusters
./kind/multi-cluster-setup.sh

# Step 2: Configure MetalLB Load Balancers
./Loadbalancer/metallb.sh

# Step 3: Install Istio Ambient Mesh
./mesh/mesh-setup.sh

# Step 4: Deploy Workloads
kubectl --context kind-ambient-cluster1 apply -f workload/httpbin.yaml
kubectl --context kind-ambient-cluster1 apply -f workload/istio-ingress.yaml
kubectl --context kind-ambient-cluster2 apply -f workload/client-cluster2.yaml

# Step 5: Verify Cross-Cluster Traffic
./verify-cross-cluster.sh
```

---

## 🧪 Verification & Inspection

### 1. Test Cross-Cluster HTTP Call

```bash
# Retrieve Cluster 1 LoadBalancer IP
INGRESS_IP=$(kubectl --context kind-ambient-cluster1 -n istio-system get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Call httpbin from Cluster 2
kubectl --context kind-ambient-cluster2 -n ambient-demo exec deploy/sleep -- curl -s "http://${INGRESS_IP}/headers"
```

### 2. Inspect Istio Ambient Data Plane (`ztunnel`)

```bash
# Check ztunnel DaemonSet pods
kubectl --context kind-ambient-cluster1 -n istio-system get pods -l app=ztunnel
kubectl --context kind-ambient-cluster2 -n istio-system get pods -l app=ztunnel

# View ztunnel access and mTLS telemetry logs
kubectl --context kind-ambient-cluster1 -n istio-system logs -l app=ztunnel --tail=20
```

---

## 🧹 Teardown

```bash
cd microclusters
./teardown-all.sh
```
