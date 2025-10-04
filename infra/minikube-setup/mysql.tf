resource "kubernetes_secret" "mysql_secret" {
  metadata {
    name      = "mysql-secret"
    namespace = kubernetes_namespace.app_ns.metadata[0].name
  }

  data = {
    MYSQL_ROOT_PASSWORD = base64encode("rootpass")
    MYSQL_DATABASE      = base64encode("myappdb")
    MYSQL_USER          = base64encode("myuser")
    MYSQL_PASSWORD      = base64encode("mypassword")
  }
}


resource "kubernetes_persistent_volume_claim" "mysql_pvc" {
    metadata {
        name      = "mysql-pvc"
        namespace = kubernetes_namespace.app_ns.metadata[0].name
    }
    
    spec {
        access_modes = ["ReadWriteOnce"]
    
        resources {
        requests = {
            storage = "1Gi"
        }
        }
    }
}


resource "kubernetes_deployment" "mysql" {
    metadata {
        name      = "mysql"
        namespace = kubernetes_namespace.app_ns.metadata[0].name
        labels = {
        app = "mysql"
        }
    }
    
    spec {
        replicas = 1
    
        selector {
        match_labels = {
            app = "mysql"
        }
        }
    
        template {
        metadata {
            labels = {
            app = "mysql"
            }
        }
    
        spec {
            container {
            name  = "mysql"
            image = "mysql:5.7"
    
            env {
                name = "MYSQL_ROOT_PASSWORD"
                value_from {
                secret_key_ref {
                    name = kubernetes_secret.mysql_secret.metadata[0].name
                    key  = "MYSQL_ROOT_PASSWORD"
                }
                }
            }
    
            env {
                name = "MYSQL_DATABASE"
                value_from {
                secret_key_ref {
                    name = kubernetes_secret.mysql_secret.metadata[0].name
                    key  = "MYSQL_DATABASE"
                }
                }
            }
    
            env {
                name = "MYSQL_USER"
                value_from {
                secret_key_ref {
                    name = kubernetes_secret.mysql_secret.metadata[0].name
                    key  = "MYSQL_USER"
                }
                }
            }
    
            env {
                name = "MYSQL_PASSWORD"
                value_from {
                secret_key_ref {
                    name = kubernetes_secret.mysql_secret.metadata[0].name
                    key  = "MYSQL_PASSWORD"
                }
                }
            }
    
            port {
                container_port = 3306
            }
    
            volume_mount {
                name       = "mysql-storage"
                mount_path = "/var/lib/mysql"
            }
            }
    
            volume {
            name = "mysql-storage"
    
            persistent_volume_claim {
                claim_name = kubernetes_persistent_volume_claim.mysql_pvc.metadata[0].name
            }
            }
        }
        }
    }
}


resource "kubernetes_service" "mysql_service" {
    metadata {
        name      = "mysql-service"
        namespace = kubernetes_namespace.app_ns.metadata[0].name
    }
    
    spec {
        selector = {
        app = kubernetes_deployment.mysql.metadata[0].labels["app"]
        }
    
        port {
        port        = 3306
        target_port = 3306
        }
    
        type = "ClusterIP"
    }
}
