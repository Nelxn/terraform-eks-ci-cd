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
      host = 
      http {
        path {
          path = "/"
          backend {
            service {
              name = kubernetes_service.flask.metadata[0].name
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
