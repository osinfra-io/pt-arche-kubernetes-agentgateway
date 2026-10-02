#!/usr/bin/env bash

set -euo pipefail

if [ "$(kubectl config current-context)" != "docker-desktop" ]; then
  echo "kubectl must use the docker-desktop context" >&2
  exit 1
fi

kubectl delete authorizationpolicy agentgateway-authentik \
  --namespace=istio-ingress \
  --ignore-not-found
kubectl delete namespace agentgateway-system --ignore-not-found

echo "AgentGateway teardown complete."
