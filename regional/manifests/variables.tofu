# Input Variables
# https://opentofu.org/docs/language/values/variables

variable "agentgateway_version" {
  description = "AgentGateway Helm chart version, used to tag the proxy's Datadog version label"
  type        = string
  default     = "v1.6.0"
}

variable "labels" {
  description = "Labels applied to AgentGateway resources"
  type        = map(string)
  default     = {}
}

variable "namespace" {
  description = "Kubernetes namespace for AgentGateway"
  type        = string
}

variable "proxy_cpu_limits" {
  description = "CPU limit for the AgentGateway proxy"
  type        = string
  default     = "500m"
}

variable "proxy_cpu_requests" {
  description = "CPU request for the AgentGateway proxy"
  type        = string
  default     = "100m"
}

variable "proxy_env" {
  description = "Additional environment variables for the AgentGateway proxy"
  type        = map(string)
  default     = {}
}

variable "proxy_memory_limits" {
  description = "Memory limit for the AgentGateway proxy"
  type        = string
  default     = "512Mi"
}

variable "proxy_memory_requests" {
  description = "Memory request for the AgentGateway proxy"
  type        = string
  default     = "128Mi"
}

variable "proxy_replicas" {
  description = "Number of AgentGateway proxy replicas"
  type        = number
  default     = 1

  validation {
    condition     = var.proxy_replicas > 0
    error_message = "proxy_replicas must be greater than zero."
  }
}
