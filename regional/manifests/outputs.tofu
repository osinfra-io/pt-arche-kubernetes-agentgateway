# Output Values
# https://opentofu.org/docs/language/values/outputs

output "agentgateway_parameters_manifest" {
  description = "Rendered AgentgatewayParameters manifest"
  value       = kubernetes_manifest.agentgateway_parameters.manifest
}
