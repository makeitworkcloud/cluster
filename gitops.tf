resource "kubernetes_namespace" "openshift_gitops" {
  metadata {
    name = "openshift-gitops-operator"
  }
  lifecycle {
    ignore_changes = [
      metadata[0].annotations["openshift.io/sa.scc.mcs"],
      metadata[0].annotations["openshift.io/sa.scc.supplemental-groups"],
      metadata[0].annotations["openshift.io/sa.scc.uid-range"],
      metadata[0].labels["security.openshift.io/scc.podSecurityLabelSync"]
    ]
  }
}

resource "kubernetes_manifest" "openshift_gitops_operator_group" {
  manifest = {
    apiVersion = "operators.coreos.com/v1"
    kind       = "OperatorGroup"
    metadata = {
      name      = "openshift-gitops-operator-tf"
      namespace = kubernetes_namespace.openshift_gitops.metadata[0].name
    }
    spec = {
      upgradeStrategy = "Default"
    }
  }
  depends_on = [kubernetes_namespace.openshift_gitops]
}


resource "kubernetes_manifest" "openshift_gitops_subscription" {
  manifest = {
    apiVersion = "operators.coreos.com/v1alpha1"
    kind       = "Subscription"
    metadata = {
      name      = "openshift-gitops-operator"
      namespace = kubernetes_namespace.openshift_gitops.metadata[0].name
    }
    spec = {
      channel             = "latest"
      name                = "openshift-gitops-operator"
      source              = "redhat-operators"
      sourceNamespace     = "openshift-marketplace"
      installPlanApproval = "Automatic"
    }
  }
  wait {
    fields = {
      "status.state" = "AtLatestKnown"
    }
  }
  depends_on = [kubernetes_manifest.openshift_gitops_operator_group]
}

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
  depends_on = [kubernetes_manifest.openshift_gitops_subscription]
}

resource "kubernetes_secret" "sops_age_key" {
  metadata {
    name      = "sops-age-key"
    namespace = "openshift-gitops"
  }
  data = {
    "key.txt" = data.sops_file.secret_vars.data["age_secret_key"]
  }
  type       = "Opaque"
  depends_on = [kubernetes_namespace.openshift_gitops]
}
