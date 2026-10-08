module "agentgateway_manifests" {
  source = "../../../regional/manifests"

  namespace = "agentgateway"

  proxy_env = {
    ADMIN_ADDR = "0.0.0.0:15000"
  }
}
