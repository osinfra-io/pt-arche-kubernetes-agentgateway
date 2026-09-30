# Local Values
# https://opentofu.org/docs/language/values/locals

locals {
  controller_helm_values = yamlencode({
    commonLabels = var.labels
    controller = {
      replicaCount = 1
    }
    resources = {
      limits = {
        cpu    = var.controller_cpu_limits
        memory = var.controller_memory_limits
      }
      requests = {
        cpu    = var.controller_cpu_requests
        memory = var.controller_memory_requests
      }
    }
  })

  gateway_name = "agentgateway-proxy"

  proxy_labels = merge(var.labels, {
    "tags.datadoghq.com/service" = "agentgateway-proxy"
    "tags.datadoghq.com/source"  = "agentgateway"
    "tags.datadoghq.com/version" = var.agentgateway_version
  })

  proxy_service_account_name = local.gateway_name
}
