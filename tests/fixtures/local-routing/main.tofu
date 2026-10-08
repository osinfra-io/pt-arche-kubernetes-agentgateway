module "local_routing" {
  source = "../../../regional/local"

  namespace = "agentgateway"
}

output "admin_policy_manifest" {
  value = module.local_routing.admin_policy_manifest
}

output "admin_route_manifest" {
  value = module.local_routing.admin_route_manifest
}

output "authentik_outpost_route_manifest" {
  value = module.local_routing.authentik_outpost_route_manifest
}

output "diagnostic_route_manifest" {
  value = module.local_routing.diagnostic_route_manifest
}

output "diagnostic_ingress_manifest" {
  value = module.local_routing.diagnostic_ingress_manifest
}

output "admin_service" {
  value = module.local_routing.admin_service
}
