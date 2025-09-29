resource "kubernetes_ingress" "flask_ingress" {
  metadata {
    name      = "flask-ingress"
    namespace = kubernetes_namespace.app_ns.metadata[0].name
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }

  spec {
    rule {
      host = "flask.local"

      http {
        path {
          path = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "flask-app-service"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
