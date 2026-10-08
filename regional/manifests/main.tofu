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
    spec = local.proxy_parameters_spec
  }
}
