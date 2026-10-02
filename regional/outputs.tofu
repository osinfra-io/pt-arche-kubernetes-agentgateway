# Output Values
# https://opentofu.org/docs/language/values/outputs

output "gateway_name" {
  description = "Name of the AgentGateway Gateway and proxy service"
  value       = local.gateway_name
}

output "namespace" {
  description = "Namespace containing AgentGateway"
  value       = var.namespace
}

output "proxy_service_account_name" {
  description = "Service account used by the AgentGateway proxy"
  value       = local.proxy_service_account_name
}

output "service_name" {
  description = "Name of the internal AgentGateway proxy service"
  value       = local.gateway_name
}

output "service_port" {
  description = "Port exposed by the internal AgentGateway proxy service"
  value       = 80
}
