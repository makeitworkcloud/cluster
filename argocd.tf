resource "kubernetes_secret" "argocd_github_repo_secret" {
  metadata {
    name      = "github-repo"
    namespace = "openshift-gitops"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }
  data = {
    url     = "https://github.com/makeitworkcloud/cluster.git"
    name    = "github-repo"
    project = "default"
    type    = "git"
  }
  depends_on = [kubernetes_manifest.openshift_gitops_subscription]
}

resource "kubernetes_manifest" "argocd_kustomize_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "kustomize"
      namespace = "openshift-gitops"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/makeitworkcloud/cluster.git"
        path           = "kustomize"
        targetRevision = "main"
      }
      destination = {
        server = "https://kubernetes.default.svc"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }
  depends_on = [kubernetes_secret.argocd_github_repo_secret]
}
