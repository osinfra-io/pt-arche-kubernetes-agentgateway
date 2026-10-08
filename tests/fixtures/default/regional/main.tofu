module "agentgateway" {
  source = "../../../../regional"

  namespace = "agentgateway"
}

output "gateway_name" {
  value = module.agentgateway.gateway_name
}

output "namespace" {
  value = module.agentgateway.namespace
}

output "service_port" {
  value = module.agentgateway.service_port
}
