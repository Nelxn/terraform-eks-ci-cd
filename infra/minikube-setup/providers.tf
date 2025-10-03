terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.44"
    }
  }
}

provider "kubernetes" {
  config_path = "/var/jenkins_home/.kube/config"
}



resource "kubernetes_namespace" "app_ns" {
  metadata {
    name = "flask-project"
  }
}