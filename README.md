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

The fixture validates ordinary HTTP traffic through:

```text
Istio gateway -> Authentik authorization -> AgentGateway -> pt-pneuma-istio-test
```

AgentGateway v1.5.0 documents Istio support through 1.30 while the platform currently uses Istio 1.31. The fixture intentionally tests the unchanged platform version. Do not downgrade Istio or select an older AgentGateway release to make the test pass.

## 📦 Release

Push a semantic version tag after tests pass:

```none
git tag vX.Y.Z
git push origin vX.Y.Z
```
