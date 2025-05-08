terraform {
  # please don't pin terraform versions.
  # stating a required minimum version should be sufficient for most use cases.
  required_version = "> 1.3"

  backend "kubernetes" {
    secret_suffix = "tfstate"
    config_path   = "~/.kube/config"
    namespace     = "tf-cluster"
  }

  # please don't pin provider versions unless there is a known bug being worked around.
  # please add comment-doc when pinning to reference upstream bugs/docs that show the reason for the pin.
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    #argocd = {
    #source = "argoproj-labs/argocd"
    #}
    sops = {
      source = "carlpett/sops"
    }
  }
}

provider "helm" {
  kubernetes {
    host        = "https://${var.cluster_host}"
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  host        = "https://${var.cluster_host}"
  config_path = "~/.kube/config"
}

#provider "argocd" {
#server_addr = "openshift-gitops-server-openshift-gitops.apps.us1aro.eastus.aroapp.io"
#username    = "admin"
#password    = data.sops_file.secret_vars.data["argocd_password"]
#}

provider "sops" {}
