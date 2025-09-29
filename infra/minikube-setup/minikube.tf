resource "null_resource" "start_minikube" {
  provisioner "local-exec" {
    command = "minikube start --driver=docker --cpus=2 --memory=2g"
  }
}


