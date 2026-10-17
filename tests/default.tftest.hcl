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
    condition     = output.namespace == "agentgateway"
    error_message = "The module must expose the fixture's explicitly supplied agentgateway namespace."
  }

  assert {
    condition     = output.service_port == 80
    error_message = "The internal AgentGateway service must expose port 80."
  }
}

run "default_manifests" {
  command = apply

  module {
    source = "./tests/fixtures/default/regional/manifests"
  }
}

run "proxy_env" {
  command = apply

  module {
    source = "./regional/manifests"
  }

  variables {
    namespace = "agentgateway"

    proxy_env = {
      ADMIN_ADDR = "0.0.0.0:15000"
    }
  }

  assert {
    condition     = output.agentgateway_parameters_manifest.spec.env[0].name == "ADMIN_ADDR" && output.agentgateway_parameters_manifest.spec.env[0].value == "0.0.0.0:15000"
    error_message = "The proxy_env variable must set the AgentGateway proxy environment, e.g. exposing its admin listener on port 15000."
  }
}
