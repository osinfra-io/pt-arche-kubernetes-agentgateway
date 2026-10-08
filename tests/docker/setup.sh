#!/usr/bin/env bash

set -euo pipefail

readonly AGENTGATEWAY_VERSION="${AGENTGATEWAY_VERSION:-v1.6.0}"
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

diagnostics() {
  echo "AgentGateway setup failed; collecting diagnostics" >&2
  helm list --namespace agentgateway-system >&2 || true
  kubectl get crd --output=name 2>/dev/null | grep '\.agentgateway\.dev$' >&2 || true
  kubectl get gateway,httproute --all-namespaces >&2 || true
  kubectl get referencegrant --namespace=istio-test >&2 || true
  kubectl get pods --namespace=agentgateway-system \
    --output=custom-columns='POD:.metadata.name,STATUS:.status.phase,CONTAINERS:.spec.containers[*].name,AMBIENT:.metadata.annotations.ambient\.istio\.io/redirection' >&2 || true
  kubectl logs --namespace=agentgateway-system deployment/agentgateway --tail=50 >&2 || true
  kubectl logs --namespace=agentgateway-system deployment/agentgateway-proxy --tail=50 >&2 || true
  kubectl logs --namespace=istio-system daemonset/ztunnel --tail=50 >&2 || true
}

trap diagnostics ERR

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
wait_for_route_condition agentgateway-admin Accepted
wait_for_route_condition agentgateway-admin ResolvedRefs

proxy_pods="$(
  kubectl get pods --namespace=agentgateway-system \
    --selector=gateway.networking.k8s.io/gateway-name=agentgateway-proxy \
    --output=jsonpath='{.items[*].metadata.name}'
)"

for pod in ${proxy_pods}; do
  kubectl wait --namespace=agentgateway-system "pod/${pod}" \
    --for=jsonpath='{.metadata.annotations.ambient\.istio\.io/redirection}'=enabled \
    --timeout=120s

  if kubectl get pod "${pod}" --namespace=agentgateway-system \
    --output=jsonpath='{.spec.containers[*].name} {.spec.initContainers[*].name}' |
    grep --quiet --word-regexp istio-proxy; then
    echo "AgentGateway proxy pod ${pod} unexpectedly has an Istio sidecar" >&2
    exit 1
  fi
done

curl --fail --insecure --silent --show-error \
  https://agentgateway.localhost/agentgateway-test/health >/dev/null
curl --fail --insecure --silent --show-error \
  https://agentgateway.localhost/agentgateway-test/metadata/cluster-name >/dev/null

redirect_headers="$(
  curl --insecure --silent --show-error --dump-header - --output /dev/null \
    https://agentgateway.localhost/agentgateway-test/auth
)"

grep --quiet '^HTTP/.* 302' <<<"${redirect_headers}"
grep --quiet '^location: https://authentik.localhost/application/o/authorize/' <<<"${redirect_headers,,}"
grep --quiet 'redirect_uri=https%3a%2f%2fagentgateway.localhost%2foutpost.goauthentik.io%2fcallback' <<<"${redirect_headers,,}"

curl --fail --insecure --silent --show-error \
  https://agentgateway.localhost/outpost.goauthentik.io/ping >/dev/null

spoofed_status="$(
  curl --insecure --silent --show-error --output /dev/null --write-out '%{http_code}' \
    --header 'X-Authentik-Username: spoofed' \
    --header 'X-Authentik-Email: spoofed@example.com' \
    --header 'X-Authentik-Groups: admins' \
    https://agentgateway.localhost/agentgateway-test/auth
)"

if [ "${spoofed_status}" != "302" ]; then
  echo "Spoofed identity headers bypassed Authentik (status ${spoofed_status})" >&2
  exit 1
fi

ui_headers="$(
  curl --insecure --silent --show-error --dump-header - --output /dev/null \
    https://agentgateway.localhost/ui/
)"

grep --quiet '^HTTP/.* 302' <<<"${ui_headers}"
grep --quiet '^location: https://authentik.localhost/application/o/authorize/' <<<"${ui_headers,,}"

echo "AgentGateway setup complete. Open https://agentgateway.localhost/agentgateway-test/auth or the admin UI at https://agentgateway.localhost/ui/ to complete browser authentication."
