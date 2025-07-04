terraform {
  # please don't pin terraform versions.
  # stating a required minimum version should be sufficient for most use cases.
  required_version = "> 1.3"

  backend "kubernetes" {
    secret_suffix = "tfstate"
    config_path   = "~/.kube/config"
  }

  # please don't pin provider versions unless there is a known bug being worked around.
  # please add comment-doc when pinning to reference upstream bugs/docs that show the reason for the pin.
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    sops = {
      source = "carlpett/sops"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "sops" {}
