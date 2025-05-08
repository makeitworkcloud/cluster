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
  depends_on = [kubernetes_manifest.openshift_gitops_operator_group]
}
