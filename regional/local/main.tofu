# Agentgateway Admin Routing Module (osinfra.io)
# https://github.com/osinfra-io/pt-arche-kubernetes-agentgateway

module "admin" {
  source = "../admin"

  gateway_name            = var.gateway_name
  hostname                = var.hostname
  istio_gateway_name      = var.istio_gateway_name
  istio_gateway_namespace = var.istio_gateway_namespace
  istio_ingress_principal = var.istio_ingress_principal
  namespace               = var.namespace
}

# Kubernetes Manifest Resource
# https://search.opentofu.org/provider/hashicorp/kubernetes/latest/docs/resources/manifest

# Backend route rewriting keeps the existing diagnostic application shared by both gateways.
resource "kubernetes_manifest" "agentgateway_backend" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "agentgateway-backend"
      namespace = var.namespace
    }
    spec = {
      hostnames = [var.hostname]
      parentRefs = [
        {
          name = var.gateway_name
        }
      ]
      rules = [
        {
          backendRefs = [
            {
              kind      = "Service"
              name      = var.diagnostic_service
              namespace = var.diagnostic_namespace
              port      = var.diagnostic_service_port
            }
          ]
          filters = [
            {
              type = "URLRewrite"
              urlRewrite = {
                path = {
                  replacePrefixMatch = "/istio-test"
                  type               = "ReplacePrefixMatch"
                }
              }
            }
          ]
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/agentgateway-test"
              }
            }
          ]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "agentgateway_ingress" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "agentgateway-ingress"
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
          backendRefs = [
            {
              name = var.gateway_name
              port = 80
            }
          ]
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/agentgateway-test"
              }
            }
          ]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "agentgateway_reference_grant" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1beta1"
    kind       = "ReferenceGrant"
    metadata = {
      name      = "agentgateway"
      namespace = var.diagnostic_namespace
    }
    spec = {
      from = [
        {
          group     = "gateway.networking.k8s.io"
          kind      = "HTTPRoute"
          namespace = var.namespace
        }
      ]
      to = [
        {
          group = ""
          kind  = "Service"
          name  = var.diagnostic_service
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "authentik_outpost" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "authentik-outpost-agentgateway"
      namespace = var.authentik_namespace
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
          backendRefs = [
            {
              name = var.authentik_service
              port = var.authentik_http_port
            }
          ]
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/outpost.goauthentik.io"
              }
            }
          ]
        }
      ]
    }
  }
}
