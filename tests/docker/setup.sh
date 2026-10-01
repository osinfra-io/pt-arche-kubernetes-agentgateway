#!/usr/bin/env bash

set -euo pipefail

readonly AGENTGATEWAY_VERSION="${AGENTGATEWAY_VERSION:-v1.5.0}"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

wait_for_route_condition() {
  local name="$1"
  local condition="$2"

  for _ in $(seq 1 60); do
    if kubectl get httproute "${name}" \
      --namespace=agentgateway-system \
      --output=jsonpath="{.status.parents[0].conditions[?(@.type=='${condition}')].status}" |
      grep --quiet True; then
      return 0
    fi
    sleep 2
  done

  echo "HTTPRoute ${name} did not reach ${condition}=True" >&2
  kubectl get httproute "${name}" --namespace=agentgateway-system --output=yaml >&2
  return 1
}

if [ "$(kubectl config current-context)" != "docker-desktop" ]; then
  echo "kubectl must use the docker-desktop context" >&2
  exit 1
fi

kubectl create namespace agentgateway-system --dry-run=client --output=yaml |
  kubectl apply --filename -
kubectl label namespace agentgateway-system istio.io/dataplane-mode=ambient --overwrite

helm upgrade --install agentgateway-crds \
  oci://cr.agentgateway.dev/charts/agentgateway-crds \
  --namespace agentgateway-system \
  --version "${AGENTGATEWAY_VERSION}" \
  --wait

helm upgrade --install agentgateway \
  oci://cr.agentgateway.dev/charts/agentgateway \
  --namespace agentgateway-system \
  --version "${AGENTGATEWAY_VERSION}" \
  --wait

kubectl apply --filename "${SCRIPT_DIR}/manifests"

kubectl rollout status deployment/agentgateway --namespace=agentgateway-system --timeout=180s
kubectl rollout status deployment/agentgateway-proxy --namespace=agentgateway-system --timeout=180s
kubectl wait --for=condition=Programmed gateway/agentgateway-proxy --namespace=agentgateway-system --timeout=180s
wait_for_route_condition agentgateway-backend Accepted
wait_for_route_condition agentgateway-backend ResolvedRefs
wait_for_route_condition agentgateway-ingress Accepted
wait_for_route_condition agentgateway-ingress ResolvedRefs

if kubectl get pods --namespace=agentgateway-system \
  --selector=gateway.networking.k8s.io/gateway-name=agentgateway-proxy \
  --output=jsonpath='{.items[*].spec.containers[*].name}' |
  grep --quiet istio-proxy; then
  echo "AgentGateway proxy unexpectedly has an Istio sidecar" >&2
  exit 1
fi

curl --fail --insecure --silent --show-error \
  https://dev.localhost/agentgateway-test/health >/dev/null
curl --fail --insecure --silent --show-error \
  https://dev.localhost/agentgateway-test/metadata/cluster-name >/dev/null

redirect_headers="$(
  curl --insecure --silent --show-error --dump-header - --output /dev/null \
    https://dev.localhost/agentgateway-test/auth
)"

grep --quiet '^HTTP/.* 302' <<<"${redirect_headers}"
grep --quiet '^location: http://localhost:9000/application/o/authorize/' <<<"${redirect_headers,,}"

echo "AgentGateway setup complete. Open https://dev.localhost/agentgateway-test/auth to complete browser authentication."
