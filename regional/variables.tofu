# Input Variables
# https://opentofu.org/docs/language/values/variables

variable "agentgateway_version" {
  description = "AgentGateway Helm chart version"
  type        = string
  default     = "v1.5.0"
}

variable "chart_repository" {
  description = "OCI repository containing the AgentGateway Helm charts"
  type        = string
  default     = "oci://cr.agentgateway.dev/charts"
}

variable "controller_cpu_limits" {
  description = "CPU limit for the AgentGateway controller"
  type        = string
  default     = "500m"
}

variable "controller_cpu_requests" {
  description = "CPU request for the AgentGateway controller"
  type        = string
  default     = "100m"
}

variable "controller_memory_limits" {
  description = "Memory limit for the AgentGateway controller"
  type        = string
  default     = "512Mi"
}

variable "controller_memory_requests" {
  description = "Memory request for the AgentGateway controller"
  type        = string
  default     = "128Mi"
}

variable "labels" {
  description = "Labels applied to AgentGateway resources"
  type        = map(string)
  default     = {}
}

variable "namespace" {
  description = "Kubernetes namespace for AgentGateway"
  type        = string
  default     = "agentgateway-system"
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
