# Kubernetes AgentGateway OpenTofu Module

[![OpenTofu Tests](https://img.shields.io/github/actions/workflow/status/osinfra-io/pt-arche-kubernetes-agentgateway/test.yml?style=for-the-badge&logo=opentofu&color=FEDA15&label=OpenTofu%20Tests)](https://github.com/osinfra-io/pt-arche-kubernetes-agentgateway/actions/workflows/test.yml) [![Dependabot](https://img.shields.io/github/actions/workflow/status/osinfra-io/pt-arche-kubernetes-agentgateway/dependabot.yml?style=for-the-badge&logo=github&color=2088FF&label=Dependabot)](https://github.com/osinfra-io/pt-arche-kubernetes-agentgateway/actions/workflows/dependabot.yml) [![Datadog Security Enabled](https://img.shields.io/badge/Datadog%20Security-Enabled-632CA6?style=for-the-badge&logo=datadog)](https://app.datadoghq.com/security/code-security/repositories?repository_id=pt-arche-kubernetes-agentgateway)

## Repository Description

Reusable OpenTofu child module that deploys the AgentGateway control plane and an internal AgentGateway proxy on GKE. The proxy is enrolled in Istio ambient mesh and exposed only through a `ClusterIP` service so the platform's existing Istio gateway remains the public TLS, Cloud Armor, Datadog AAP, and Authentik enforcement point.

The initial module intentionally provides ordinary HTTP connectivity only. LLM providers, MCP servers, A2A routing, provider credentials, inference routing, and AgentGateway-native MCP OAuth are not configured.

## 🔩 Usage

The repository root is not a consumable module. Install both child modules once in each Pneuma gateway cluster, `//regional` before `//regional/manifests`.

`AgentgatewayParameters` is a CRD installed by `//regional`'s own Helm charts, so `kubernetes_manifest` cannot plan it in the same apply as the chart install on a fresh cluster — it must be applied as a separate, later workspace. The `Gateway` resource stays in `//regional` because it relies on the `gateway.networking.k8s.io` CRD, which GKE's Gateway API feature (or the local Docker Desktop fixture) installs ahead of this module, not something `//regional` itself installs.

> [!TIP]
> You can check the [tests/fixtures](tests/fixtures) directory for example configurations. These fixtures set up the system for testing by providing all the necessary initial code, thus creating good examples on which to base your configurations.

## 🛠️ Tools

- [AgentGateway](https://agentgateway.dev/docs/kubernetes/latest/)
- [Helm](https://github.com/helm/helm)
- [osinfra-pre-commit-hooks](https://github.com/osinfra-io/pt-techne-pre-commit-hooks)
- [pre-commit](https://github.com/pre-commit/pre-commit)

## 📋 Skills and Knowledge

Links to documentation and other resources required to develop and iterate in this repository successfully.

- [AgentGateway](https://agentgateway.dev/docs/kubernetes/latest/)

## 🔍 Tests

All tests are [mocked](https://opentofu.org/docs/cli/commands/test/#the-mock_provider-blocks) allowing us to test the module without creating infrastructure or requiring credentials. The trade-offs are acceptable in favor of speed and simplicity. In an OpenTofu test, a mocked provider or resource will generate fake data for all computed attributes that would normally be provided by the underlying provider APIs.

```none
tofu init
tofu test
```

### Local Istio and Authentik compatibility

Use the `test-local-gateway-stack` skill from the [`platform-grouping` plugin](https://github.com/osinfra-io/pt-ai-plugins/tree/main/plugins/platform-grouping) for setup, browser-authentication checks, diagnostics, and teardown:

```text
Use the test-local-gateway-stack skill to test this checkout.
```

Do not port-forward the proxy admin port `15000`: it bypasses Authentik. Access the admin UI through the authenticated Istio gateway.

## 📦 Release

Push a semantic version tag after tests pass:

```none
git tag vX.Y.Z
git push origin vX.Y.Z
```
