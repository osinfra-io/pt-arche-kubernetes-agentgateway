#!/usr/bin/env bash

set -euo pipefail

kubectl delete authorizationpolicy agentgateway-authentik \
  --namespace=istio-ingress \
  --ignore-not-found
kubectl delete namespace agentgateway-system --ignore-not-found

echo "AgentGateway teardown complete."
