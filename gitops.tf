resource "kubernetes_cluster_role_binding" "openshift_gitops_cluster_admin" {
  metadata {
    name = "openshift-gitops-operator-cluster-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "openshift-gitops-argocd-application-controller"
    namespace = "openshift-gitops"
  }
}

