module "agentgateway_manifests" {
  source = "../../../regional/manifests"

  namespace = "agentgateway"

  proxy_env = {
    ADMIN_ADDR = "0.0.0.0:15000"
  }
}

output "agentgateway_parameters_manifest" {
  value = module.agentgateway_manifests.agentgateway_parameters_manifest
}
