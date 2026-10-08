#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$(kubectl config current-context)" != "docker-desktop" ]; then
  echo "kubectl must use the docker-desktop context" >&2
  exit 1
fi

kubectl delete --filename "${SCRIPT_DIR}/manifests" --ignore-not-found --wait=true

for release in agentgateway agentgateway-crds; do
  if helm status "${release}" --namespace agentgateway-system >/dev/null 2>&1; then
    helm uninstall "${release}" --namespace agentgateway-system --wait
  fi
done

# The controller creates this GatewayClass at runtime, so Helm does not remove it.
kubectl delete gatewayclass agentgateway --ignore-not-found
kubectl delete namespace agentgateway-system --ignore-not-found --wait=true

remaining="$(
  {
    kubectl get crd --output=name | grep '\.agentgateway\.dev$' || true
    kubectl get gatewayclass,clusterrole,clusterrolebinding --output=name 2>/dev/null | grep agentgateway || true
  }
)"

if [ -n "${remaining}" ]; then
  echo "AgentGateway resources remain after teardown:" >&2
  echo "${remaining}" >&2
  exit 1
fi

echo "AgentGateway teardown complete."
