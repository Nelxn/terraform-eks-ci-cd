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
                    sh 'terraform init -upgrade'
                }
            }
        }

        stage('Kubernetes Cleanup') {
            steps {
                sh 'kubectl --kubeconfig=$KUBECONFIG delete deployment flask-app -n flask-project --ignore-not-found'
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
                        kubectl --kubeconfig=$KUBECONFIG -n flask-project get pods
                        kubectl --kubeconfig=$KUBECONFIG -n flask-project get svc
                        kubectl --kubeconfig=$KUBECONFIG -n flask-project get ingress
                    """
                }
            }
        }
    }

    post {
        failure {
            echo "Deployment failed. Please check logs above for issues."
        }
        success {
            echo "Flask app deployed via Terraform to Minikube (on host)!"
        }
    }
}
