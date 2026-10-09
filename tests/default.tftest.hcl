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

run "local_admin_listener" {
  command = apply

  module {
    source = "./tests/fixtures/local-manifests"
  }

  assert {
    condition     = output.agentgateway_parameters_manifest.spec.env[0].name == "ADMIN_ADDR" && output.agentgateway_parameters_manifest.spec.env[0].value == "0.0.0.0:15000"
    error_message = "The local AgentGateway proxy must expose its admin listener on port 15000."
  }
}

run "local_gateway_routing" {
  command = apply

  module {
    source = "./tests/fixtures/local-routing"
  }

  assert {
    condition     = output.diagnostic_route_manifest.spec.rules[0].filters[0].urlRewrite.path.replacePrefixMatch == "/istio-test"
    error_message = "The AgentGateway diagnostic route must rewrite its prefix to /istio-test."
  }

  assert {
    condition     = output.diagnostic_route_manifest.spec.rules[0].matches[0].path.value == "/agentgateway-test"
    error_message = "The AgentGateway route must retain the diagnostic /agentgateway-test path."
  }

  assert {
    condition     = output.diagnostic_ingress_manifest.spec.hostnames[0] == "agentgateway.localhost" && output.diagnostic_ingress_manifest.spec.rules[0].matches[0].path.value == "/agentgateway-test"
    error_message = "The diagnostic route must be exposed only through the Istio ingress Gateway at agentgateway.localhost."
  }

  assert {
    condition     = output.authentik_outpost_route_manifest.spec.rules[0].backendRefs[0].port == 80
    error_message = "The Authentik outpost route must target the in-cluster HTTP Service port 80."
  }

  assert {
    condition     = output.authentik_outpost_route_manifest.spec.rules[0].matches[0].path.value == "/outpost.goauthentik.io"
    error_message = "The Authentik outpost path must remain routed through Istio."
  }

  assert {
    condition     = output.admin_policy_manifest.spec.action == "DENY" && output.admin_policy_manifest.spec.rules[0].to[0].operation.ports[0] == "15000"
    error_message = "Unauthorized in-mesh access to AgentGateway admin port 15000 must be denied."
  }

  assert {
    condition     = output.admin_route_manifest.spec.rules[1].backendRefs[0].port == 15000
    error_message = "The admin route must route through the Istio ingress Gateway to the protected admin service."
  }

  assert {
    condition     = output.admin_service.spec[0].type == "ClusterIP" && output.admin_policy_manifest.spec.rules[0].from[0].source.notPrincipals == ["cluster.local/ns/istio-ingress/sa/gateway-istio"]
    error_message = "The admin listener must stay internal and accept only the trusted ingress identity."
  }

  assert {
    condition     = [for match in output.admin_route_manifest.spec.rules[1].matches : match.path.value] == ["/ui", "/api", "/config_dump"]
    error_message = "Shared admin routing must retain the UI and its backing admin endpoints."
  }
}
