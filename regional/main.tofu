# Helm Release
# https://search.opentofu.org/provider/hashicorp/helm/latest/docs/resources/release

resource "helm_release" "agentgateway" {
  depends_on = [
    helm_release.agentgateway_crds,
    kubernetes_namespace_v1.agentgateway
  ]

  chart     = "${var.chart_repository}/agentgateway"
  name      = "agentgateway"
  namespace = var.namespace

  values = [
    local.controller_helm_values
  ]

  version = var.agentgateway_version
}

resource "helm_release" "agentgateway_crds" {
  depends_on = [
    kubernetes_namespace_v1.agentgateway
  ]

  chart     = "${var.chart_repository}/agentgateway-crds"
  name      = "agentgateway-crds"
  namespace = var.namespace
  version   = var.agentgateway_version
}

# Kubernetes Manifest Resource
# https://search.opentofu.org/provider/hashicorp/kubernetes/latest/docs/resources/manifest

resource "kubernetes_manifest" "agentgateway" {
  depends_on = [
    helm_release.agentgateway,
    kubernetes_manifest.agentgateway_parameters
  ]

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      labels    = var.labels
      name      = local.gateway_name
      namespace = var.namespace
    }
    spec = {
      gatewayClassName = "agentgateway"
      infrastructure = {
        parametersRef = {
          group = "agentgateway.dev"
          kind  = "AgentgatewayParameters"
          name  = local.gateway_name
        }
      }
      listeners = [
        {
          allowedRoutes = {
            namespaces = {
              from = "All"
            }
          }
          name     = "http"
          port     = 80
          protocol = "HTTP"
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "agentgateway_parameters" {
  depends_on = [
    helm_release.agentgateway
  ]

  manifest = {
    apiVersion = "agentgateway.dev/v1alpha1"
    kind       = "AgentgatewayParameters"
    metadata = {
      labels    = var.labels
      name      = local.gateway_name
      namespace = var.namespace
    }
    spec = {
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
    }
  }
}

# Kubernetes Namespace Resource
# https://search.opentofu.org/provider/hashicorp/kubernetes/latest/docs/resources/namespace_v1

resource "kubernetes_namespace_v1" "agentgateway" {
  metadata {
    labels = merge(var.labels, {
      "istio.io/dataplane-mode" = "ambient"
    })

    name = var.namespace
  }
}
