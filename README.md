# Kubernetes AgentGateway OpenTofu Module

[![OpenTofu Tests](https://img.shields.io/github/actions/workflow/status/osinfra-io/pt-arche-kubernetes-agentgateway/test.yml?style=for-the-badge&logo=opentofu&color=FEDA15&label=OpenTofu%20Tests)](https://github.com/osinfra-io/pt-arche-kubernetes-agentgateway/actions/workflows/test.yml) [![Dependabot](https://img.shields.io/github/actions/workflow/status/osinfra-io/pt-arche-kubernetes-agentgateway/dependabot.yml?style=for-the-badge&logo=github&color=2088FF&label=Dependabot)](https://github.com/osinfra-io/pt-arche-kubernetes-agentgateway/actions/workflows/dependabot.yml) [![Datadog Security Enabled](https://img.shields.io/badge/Datadog%20Security-Enabled-632CA6?style=for-the-badge&logo=datadog)](https://app.datadoghq.com/security/code-security/repositories?repository_id=pt-arche-kubernetes-agentgateway)

## Repository Description

Reusable OpenTofu child module that deploys the AgentGateway control plane and an internal AgentGateway proxy on GKE. The proxy is enrolled in Istio ambient mesh and exposed only through a `ClusterIP` service so the platform's existing Istio gateway remains the public TLS, Cloud Armor, Datadog AAP, and Authentik enforcement point.

The initial module intentionally provides ordinary HTTP connectivity only. LLM providers, MCP servers, A2A routing, provider credentials, inference routing, and AgentGateway-native MCP OAuth are not configured.

## 🔩 Usage

Enable Gateway API before deploying. Apply `//regional` before `//regional/manifests` in a separate workspace: the latter cannot plan `AgentgatewayParameters` until the Helm charts have installed its CRD. The repository root is not a consumable module.

Create the namespace in the consuming root, label it `istio.io/dataplane-mode=ambient`, and pass its name explicitly to the deployment and manifest modules. The reusable modules do not create namespaces or select a default; local fixtures use `agentgateway`.

The `//regional/admin` submodule publishes the admin UI and backing APIs through a dedicated Istio hostname while keeping port `15000` internal and restricted to the ingress principal. The caller must configure Authentik browser enforcement on that hostname before applying the admin routes. The local routing module calls the same submodule and retains moves for existing admin resources.

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

All OpenTofu tests are [mocked](https://opentofu.org/docs/cli/commands/test/#the-mock_provider-blocks) allowing us to test the module without creating infrastructure or requiring credentials. The trade-offs are acceptable in favor of speed and simplicity. In an OpenTofu test, a mocked provider or resource will generate fake data for all computed attributes that would normally be provided by the underlying provider APIs.

```none
tofu init
tofu test
```

### Local gateway-stack testing

Run this command in Copilot CLI with the [`platform-grouping` plugin](https://github.com/osinfra-io/pt-ai-plugins/tree/main/plugins/platform-grouping) installed:

```text
/platform-grouping:test-local-gateway-stack
```

Do not port-forward the proxy admin port `15000`: it bypasses Authentik. Access the admin UI through the authenticated Istio gateway.

## 📦 Release

Push a semantic version tag after tests pass:

```none
git tag vX.Y.Z
git push origin vX.Y.Z
```
