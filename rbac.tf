resource "kubernetes_service_account" "adminsa" {
  metadata {
    name      = "adminsa"
    namespace = "kube-system"
  }
  automount_service_account_token = true
}

resource "kubernetes_cluster_role_binding" "adminsa" {
  metadata {
    name = "adminsa"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.adminsa.metadata.0.name
    namespace = kubernetes_service_account.adminsa.metadata.0.namespace
  }
  depends_on = [kubernetes_service_account.adminsa]
}

resource "kubernetes_secret" "adminsa" {
  metadata {
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.adminsa.metadata.0.name
    }
    generate_name = "adminsa-token-"
    namespace     = "kube-system"
  }

  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true
  depends_on                     = [kubernetes_service_account.adminsa]
}