# Helm Release
# https://search.opentofu.org/provider/hashicorp/helm/latest/docs/resources/release

resource "helm_release" "agentgateway" {
  depends_on = [
    helm_release.agentgateway_crds
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
  chart      = "${var.chart_repository}/agentgateway-crds"
  name       = "agentgateway-crds"
  namespace  = var.namespace
  postrender = var.crds_postrender
  version    = var.agentgateway_version
}

# Kubernetes Manifest Resource
# https://search.opentofu.org/provider/hashicorp/kubernetes/latest/docs/resources/manifest

# The gateway.networking.k8s.io Gateway CRD is a cluster-level prerequisite enabled by GKE's
# Gateway API feature (and installed ahead of this module in the local Docker Desktop fixture),
# not something this module's own Helm charts install. `kubernetes_manifest` reads that CRD's
# schema at plan time, so it is safe to keep this resource here. AgentgatewayParameters, by
# contrast, is a CRD installed by helm_release.agentgateway_crds in this same apply, so creating
# it here would fail planning on a fresh cluster; it lives in //regional/manifests instead, applied
# as a separate, later workspace.
resource "kubernetes_manifest" "agentgateway" {
  depends_on = [
    helm_release.agentgateway
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
