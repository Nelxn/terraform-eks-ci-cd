resource "kubernetes_deployment" "app_deployment" {
    metadata {
        name = "flask-app"
        labels = {
        app = "app"
        }
    }

    spec {
        replicas = 1

        selector {
        match_labels = {
            app = "app"
        }
        }

        template {
        metadata {
            labels = {
            app = "app"
            }
        }

        spec {
            container {
            name  = "app-container"
            image = "your-dockerhub-username/your-app-image:latest"  # Replace with your Docker Hub username and image name

            env {
                name  = "DB_HOST"
                value = kubernetes_service.mysql_service.metadata[0].name
            }

            env {
                name = "DB_USER"
                value_from {
                secret_key_ref {
                    name = kubernetes_secret.mysql_secret.metadata[0].name
                    key  = "MYSQL_USER"
                }
                }
            }

            env {
                name = "DB_PASSWORD"
                value_from {
                secret_key_ref {
                    name = kubernetes_secret.mysql_secret.metadata[0].name
                    key  = "MYSQL_PASSWORD"
                }
                }
            }

            env {
                name = "DB_NAME"
                value_from {
                secret_key_ref {
                    name = kubernetes_secret.mysql_secret.metadata[0].name
                    key  = "MYSQL_DATABASE"
                }
                }
            }

            port {
                container_port = 5000
            }
            }
        }
        }
    }
}


resource "kubernetes_service" "app_service" {
    metadata {
        name = "flask-app-service"
        labels = {
        app = "app"
        }
    }

    spec {
        selector = {
        app = kubernetes_deployment.app_deployment.metadata[0].labels.app
        }
        port {
        port        = 80
        target_port = 5000
        }
        type = "ClusterIP"
    }
}
