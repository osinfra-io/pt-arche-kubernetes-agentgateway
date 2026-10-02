# Local Values
# https://opentofu.org/docs/language/values/locals

locals {
  # Must match local.gateway_name in //regional; the two modules are separate OpenTofu roots
  # and cannot reference each other's state, so the stable proxy naming convention is
  # duplicated rather than computed.
  gateway_name = "agentgateway-proxy"

  proxy_labels = merge(var.labels, {
    "tags.datadoghq.com/service" = "agentgateway-proxy"
    "tags.datadoghq.com/source"  = "agentgateway"
    "tags.datadoghq.com/version" = var.agentgateway_version
  })
}
