# Test
# https://opentofu.org/docs/cli/commands/test

mock_provider "helm" {}
mock_provider "kubernetes" {}

run "default_regional" {
  command = apply

  module {
    source = "./tests/fixtures/default/regional"
  }

  assert {
    condition     = output.gateway_name == "agentgateway-proxy"
    error_message = "The default Gateway name must remain stable for consumers."
  }

  assert {
    condition     = output.namespace == "agentgateway-system"
    error_message = "The default namespace must be agentgateway-system."
  }

  assert {
    condition     = output.service_port == 80
    error_message = "The internal AgentGateway service must expose port 80."
  }
}
