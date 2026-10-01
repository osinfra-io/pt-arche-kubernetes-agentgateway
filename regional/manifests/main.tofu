# Kubernetes Manifest Resource
# https://search.opentofu.org/provider/hashicorp/kubernetes/latest/docs/resources/manifest

# AgentgatewayParameters is a CRD installed by helm_release.agentgateway_crds in //regional.
# kubernetes_manifest reads that CRD's schema at plan time, so this resource must live in its
# own apply, run after //regional, rather than alongside the Helm releases that install it.
resource "kubernetes_manifest" "agentgateway_parameters" {
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
