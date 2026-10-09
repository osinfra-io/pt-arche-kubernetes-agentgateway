# Input Variables
# https://opentofu.org/docs/language/values/variables

variable "gateway_name" {
  default     = "agentgateway-proxy"
  description = "Agentgateway proxy Gateway whose admin listener is exposed"
  type        = string
}

variable "hostname" {
  description = "Dedicated hostname protected by Authentik on the Istio ingress gateway"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]+[a-z0-9]$", var.hostname))
    error_message = "hostname must be a DNS hostname without a scheme, wildcard, port, or path."
  }
}

variable "istio_gateway_name" {
  default     = "gateway"
  description = "Istio ingress Gateway name"
  type        = string
}

variable "istio_gateway_namespace" {
  default     = "istio-ingress"
  description = "Namespace containing the Istio ingress Gateway"
  type        = string
}

variable "istio_ingress_principal" {
  default     = "cluster.local/ns/istio-ingress/sa/gateway-istio"
  description = "Only mesh principal allowed to reach the admin listener"
  type        = string
}

variable "namespace" {
  description = "Namespace containing the agentgateway proxy"
  type        = string
}
