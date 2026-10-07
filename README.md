# Kubernetes AgentGateway OpenTofu Module

[![OpenTofu Tests](https://img.shields.io/github/actions/workflow/status/osinfra-io/pt-arche-kubernetes-agentgateway/test.yml?style=for-the-badge&logo=opentofu&color=FEDA15&label=OpenTofu%20Tests)](https://github.com/osinfra-io/pt-arche-kubernetes-agentgateway/actions/workflows/test.yml) [![Dependabot](https://img.shields.io/github/actions/workflow/status/osinfra-io/pt-arche-kubernetes-agentgateway/dependabot.yml?style=for-the-badge&logo=github&color=2088FF&label=Dependabot)](https://github.com/osinfra-io/pt-arche-kubernetes-agentgateway/actions/workflows/dependabot.yml) [![Datadog Security Enabled](https://img.shields.io/badge/Datadog%20Security-Enabled-632CA6?style=for-the-badge&logo=datadog)](https://app.datadoghq.com/security/code-security/repositories?repository_id=pt-arche-kubernetes-agentgateway)

## Repository Description

Reusable OpenTofu child module that deploys the AgentGateway control plane and an internal AgentGateway proxy on GKE. The proxy is enrolled in Istio ambient mesh and exposed only through a `ClusterIP` service so the platform's existing Istio gateway remains the public TLS, Cloud Armor, Datadog AAP, and Authentik enforcement point.

The initial module intentionally provides ordinary HTTP connectivity only. LLM providers, MCP servers, A2A routing, provider credentials, inference routing, and AgentGateway-native MCP OAuth are not configured.

## 🔩 Usage

The repository root is not a consumable module. Install both child modules once in each Pneuma gateway cluster, `//regional` before `//regional/manifests`.

| Module | Purpose | Variables |
| --- | --- | --- |
| `//regional` | Installs the `agentgateway-crds` and `agentgateway` OCI Helm charts, creates an ambient-labeled `agentgateway-system` namespace, and provisions the internal HTTP `Gateway` using `gatewayClassName: agentgateway`. | [`regional/variables.tofu`](regional/variables.tofu) |
| `//regional/manifests` | Creates the `AgentgatewayParameters` custom resource that configures the proxy's replicas, resources, and service. | [`regional/manifests/variables.tofu`](regional/manifests/variables.tofu) |

```hcl
module "kubernetes_agentgateway" {
  source = "github.com/osinfra-io/pt-arche-kubernetes-agentgateway//regional?ref=<commit_sha>" # v0.1.0

  labels = module.core_helpers.labels
}

module "kubernetes_agentgateway_manifests" {
  source = "github.com/osinfra-io/pt-arche-kubernetes-agentgateway//regional/manifests?ref=<commit_sha>" # v0.1.0

  labels = module.core_helpers.labels
}
```

`AgentgatewayParameters` is a CRD installed by `//regional`'s own Helm charts, so `kubernetes_manifest` cannot plan it in the same apply as the chart install on a fresh cluster — it must be applied as a separate, later workspace. The `Gateway` resource stays in `//regional` because it relies on the `gateway.networking.k8s.io` CRD, which GKE's Gateway API feature (or the local Docker Desktop fixture) installs ahead of this module, not something `//regional` itself installs.

## 🛠️ Tools

- [AgentGateway](https://agentgateway.dev/docs/kubernetes/latest/)
- [Helm](https://github.com/helm/helm)
- [osinfra-pre-commit-hooks](https://github.com/osinfra-io/pt-techne-pre-commit-hooks)
- [pre-commit](https://github.com/pre-commit/pre-commit)

## 🔍 Tests

Mocked OpenTofu tests require no infrastructure or credentials.

```none
tofu init
tofu test
```

### Local Istio and Authentik compatibility

The `tests/docker` fixture layers AgentGateway onto the existing Docker Desktop Istio ambient and Authentik fixture. Run the Authentik fixture and `pt-arche-kubernetes-istio/tests/docker/setup.sh` first, then run:

```none
tests/docker/setup.sh
```

The fixture validates browser authentication through:

```text
Istio gateway -> Authentik authorization -> AgentGateway -> pt-pneuma-istio-test
```

Setup fails, and prints Helm, CRD, route, pod, and ztunnel diagnostics, unless the AgentGateway controller and proxy are ready and ambient-enrolled without an `istio-proxy` sidecar, the Gateway is `Programmed`, the HTTPRoutes are `Accepted` and `ResolvedRefs`, the public health and metadata paths return `200`, `/agentgateway-test/auth` redirects to Authentik with a callback on `agentgateway.localhost` even when spoofed `X-Authentik-*` headers are sent, and the Authentik outpost path answers on `agentgateway.localhost`. The fixture serves AgentGateway on its own host, `agentgateway.localhost`, through the Istio gateway's `*.localhost` listener; the Istio test workload stays on `dev.localhost` and Authentik on `authentik.localhost`. Open `https://agentgateway.localhost/agentgateway-test/auth` to complete sign-in; success returns the identity diagnostic built from the headers Authentik forwards.

The AgentGateway admin UI is served at `https://agentgateway.localhost/ui/` (`/` redirects there) behind the Authentik policy, which protects every path on the host except the public health and metadata diagnostics and the Authentik outpost callback. The fixture binds the proxy admin listener to the pod IP, routes `/ui`, `/api`, and `/config_dump` from the Istio gateway to the `agentgateway-proxy-admin` Service, and applies a ztunnel `DENY` policy so only the Istio ingress gateway identity can reach port `15000`. Do not use `kubectl port-forward` to port `15000` for this test because it bypasses Authentik.

Run `tests/docker/teardown.sh` before the Istio teardown. It removes the fixture manifests, both Helm releases, the AgentGateway CRDs, the controller-created `GatewayClass`, and the `agentgateway-system` namespace, then fails if any AgentGateway resources remain.

### Compatibility result

AgentGateway v1.6.0, the latest stable release, passes against the unchanged platform Istio 1.31.0 ambient mesh, Gateway API v1.4.0, and Authentik 2026.8.3: authenticated requests return the identity diagnostic, spoofed identity headers are overwritten or redirected, and ztunnel reports mutual TLS for `gateway-istio -> agentgateway-proxy -> istio-test`. Do not downgrade Istio or select an older AgentGateway release to make the test pass.

## 📦 Release

Push a semantic version tag after tests pass:

```none
git tag vX.Y.Z
git push origin vX.Y.Z
```
