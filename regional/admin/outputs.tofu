# Output Values
# https://opentofu.org/docs/language/values/outputs

output "admin_policy_manifest" {
  description = "Ingress-only admin-port policy"
  value       = kubernetes_manifest.agentgateway_admin_authorization.manifest
}

output "admin_route_manifest" {
  description = "Dedicated-host UI and backing admin API route"
  value       = kubernetes_manifest.agentgateway_admin.manifest
}

output "admin_service" {
  description = "Internal admin listener Service"
  value       = kubernetes_service_v1.agentgateway_admin
}
