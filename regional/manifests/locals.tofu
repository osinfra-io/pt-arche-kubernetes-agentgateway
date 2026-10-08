# Local Values
# https://opentofu.org/docs/language/values/locals

locals {
  proxy_parameters_spec = merge({
    deployment = {
      spec = {
        replicas = var.proxy_replicas
        template = {
          metadata = {
            labels = local.proxy_labels
          }
        }
      }
    }
    logging = {
      format = "json"
    }
    resources = {
      limits = {
        cpu    = var.proxy_cpu_limits
        memory = var.proxy_memory_limits
      }
      requests = {
        cpu    = var.proxy_cpu_requests
        memory = var.proxy_memory_requests
      }
    }
    service = {
      spec = {
        type = "ClusterIP"
      }
    }
    }, var.proxy_env == {} ? {} : {
    env = [for name, value in var.proxy_env : { name = name, value = value }]
  })

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
