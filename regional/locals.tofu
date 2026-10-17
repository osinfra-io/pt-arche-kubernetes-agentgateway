# Local Values
# https://opentofu.org/docs/language/values/locals

locals {
  agentgateway_chart      = "${var.chart_repository}/agentgateway"
  agentgateway_crds_chart = "${var.chart_repository}/agentgateway-crds"

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

  proxy_service_account_name = local.gateway_name
}
