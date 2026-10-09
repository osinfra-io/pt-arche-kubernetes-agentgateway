# Kubernetes Manifest Resource
# https://search.opentofu.org/provider/hashicorp/kubernetes/latest/docs/resources/manifest

resource "kubernetes_manifest" "agentgateway_admin" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "agentgateway-admin"
      namespace = var.namespace
    }
    spec = {
      hostnames = [var.hostname]
      parentRefs = [
        {
          name      = var.istio_gateway_name
          namespace = var.istio_gateway_namespace
        }
      ]
      rules = [
        {
          filters = [
            {
              requestRedirect = {
                path = {
                  replaceFullPath = "/ui/"
                  type            = "ReplaceFullPath"
                }
                statusCode = 302
              }
              type = "RequestRedirect"
            }
          ]
          matches = [
            {
              path = {
                type  = "Exact"
                value = "/"
              }
            }
          ]
        },
        {
          backendRefs = [
            {
              name = local.service_name
              port = 15000
            }
          ]
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/ui"
              }
            },
            {
              path = {
                type  = "PathPrefix"
                value = "/api"
              }
            },
            {
              path = {
                type  = "Exact"
                value = "/config_dump"
              }
            }
          ]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "agentgateway_admin_authorization" {
  manifest = {
    apiVersion = "security.istio.io/v1"
    kind       = "AuthorizationPolicy"
    metadata = {
      name      = "agentgateway-admin"
      namespace = var.namespace
    }
    spec = {
      action = "DENY"
      rules = [
        {
          from = [
            {
              source = {
                notPrincipals = [var.istio_ingress_principal]
              }
            }
          ]
          to = [
            {
              operation = {
                ports = ["15000"]
              }
            }
          ]
        }
      ]
      selector = {
        matchLabels = {
          "gateway.networking.k8s.io/gateway-name" = var.gateway_name
        }
      }
    }
  }
}

# Kubernetes Service Resource
# https://search.opentofu.org/provider/hashicorp/kubernetes/latest/docs/resources/service_v1

resource "kubernetes_service_v1" "agentgateway_admin" {
  metadata {
    name      = local.service_name
    namespace = var.namespace
  }

  spec {
    port {
      name        = "http-admin"
      port        = 15000
      target_port = 15000
    }

    selector = {
      "gateway.networking.k8s.io/gateway-name" = var.gateway_name
    }

    type = "ClusterIP"
  }
}
