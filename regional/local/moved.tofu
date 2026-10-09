# Moved Resources
# https://opentofu.org/docs/language/modules/develop/refactoring

moved {
  from = kubernetes_manifest.agentgateway_admin
  to   = module.admin.kubernetes_manifest.agentgateway_admin
}

moved {
  from = kubernetes_manifest.agentgateway_admin_authorization
  to   = module.admin.kubernetes_manifest.agentgateway_admin_authorization
}

moved {
  from = kubernetes_service_v1.agentgateway_admin
  to   = module.admin.kubernetes_service_v1.agentgateway_admin
}
