pipeline {
    agent any

    environment {
        KUBECONFIG = "${HOME}/.kube/config"
    }

    stages {
        stage('Fix Kubeconfig for Minikube in Docker') {
            steps {
                script {
                    sh """
                        # Remove literal \${HOME} if present from previous bad runs
                        sed -i 's#\\\${HOME}#'$HOME'#g' \$KUBECONFIG

                        # Replace Mac path with Jenkins home
                        sed -i "s#/Users/mac/.minikube#\$HOME/.minikube#g" \$KUBECONFIG

                        # Replace 127.0.0.1 with host.docker.internal
                        sed -i "s#127.0.0.1#host.docker.internal#g" \$KUBECONFIG

                        # Remove CA and set skip TLS (for local dev)
                        sed -i '/certificate-authority:/d' \$KUBECONFIG
                        sed -i '/server:/a\\    insecure-skip-tls-verify: true' \$KUBECONFIG

                        # Show for debug
                        grep ".minikube" \$KUBECONFIG
                    """
                }
            }
        }

        stage('Check kubectl connectivity') {
            steps {
                sh "kubectl --insecure-skip-tls-verify=true get nodes"
            }
        }

        stage('Terraform Init') {
            steps {
                dir('infra/minikube-setup') {
                    sh 'terraform init'
                }
            }
        }

        stage('Kubernetes Cleanup') {
            steps {
                // Delete the deployment if it exists to avoid "already exists" error
                sh 'kubectl delete deployment flask-app -n flask-project --ignore-not-found'
            }
        }

        stage('Terraform State Fix') {
            steps {
                dir('infra/minikube-setup') {
                    // Remove the tainted resource to avoid identity errors
                    sh 'terraform state rm kubernetes_deployment.app_deployment || true'
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
                        kubectl --insecure-skip-tls-verify=true -n flask-project get pods
                        kubectl --insecure-skip-tls-verify=true -n flask-project get svc
                        kubectl --insecure-skip-tls-verify=true -n flask-project get ingress
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
            echo "Flask app deployed via Terraform to Minikube!"
        }
    }
}