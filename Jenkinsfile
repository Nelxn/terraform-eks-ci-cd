pipeline {
    agent any

    environment {
        KUBECONFIG = "${HOME}/.kube/config"
    }

    stages {
        stage('Check kubectl connectivity') {
            steps {
                sh "kubectl --kubeconfig=$KUBECONFIG get nodes"
            }
        }

        stage('Terraform Init') {
            steps {
                dir('infra/minikube-setup') {
                    sh 'terraform init'
                }
            }
        }

        stage('Pre-cleanup') {
            steps {
                script {
                    sh """
                        echo "🧹 Cleaning up old Kubernetes resources..."
                        # Delete namespace (if stuck, force cleanup later)
                        kubectl --kubeconfig=$KUBECONFIG delete ns flask-project --ignore-not-found || true
                        
                        echo "🧹 Resetting Terraform state..."
                        cd infra/minikube-setup
                        terraform state rm kubernetes_namespace.app_ns || true
                        terraform state rm kubernetes_deployment.app_deployment || true
                        terraform state rm kubernetes_service.app_service || true
                        terraform state rm kubernetes_ingress.app_ingress || true
                    """
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('infra/minikube-setup') {
                    sh 'terraform apply --auto-approve'
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    sh """
                        echo "✅ Pods:"
                        kubectl --kubeconfig=$KUBECONFIG -n flask-project get pods
                        
                        echo "✅ Services:"
                        kubectl --kubeconfig=$KUBECONFIG -n flask-project get svc
                        
                        echo "✅ Ingress:"
                        kubectl --kubeconfig=$KUBECONFIG -n flask-project get ingress
                    """
                }
            }
        }
    }

    post {
        failure {
            echo "❌ Deployment failed. Pipeline cleaned up state. Check logs for details."
        }
        success {
            echo "🚀 Flask app deployed via Terraform to Minikube (on host)!"
        }
    }
}
