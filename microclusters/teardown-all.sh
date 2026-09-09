#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================================================"
echo "🧹 TEARING DOWN ALL KIND CLUSTERS"
echo "================================================================"

bash "${SCRIPT_DIR}/kind/multi-cluster-teardown.sh"
