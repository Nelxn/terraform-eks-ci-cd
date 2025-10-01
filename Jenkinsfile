pipeline {
    agent any

    environment {
        // Use Jenkins home as kube/minikube mount points inside container
        KUBECONFIG = "${env.HOME}/.kube/config"
    }

    stages {
        stage('Prepare Kubeconfig for Jenkins + Minikube') {
            steps {
                script {
                    // Fix Minikube path references in kubeconfig
                    sh '''
                        # Update .minikube paths in kubeconfig
                        sed -i 's#/Users/mac/.minikube#${HOME}/.minikube#g' ${KUBECONFIG}
                        # Use host.docker.internal to let Jenkins in Docker reach host's minikube
                        sed -i 's#127.0.0.1#host.docker.internal#g' ${KUBECONFIG}
                        # Remove certificate-authority and add insecure-skip-tls-verify for local dev
                        sed -i '/certificate-authority:/d' ${KUBECONFIG}
                        sed -i '/server:/a\\    insecure-skip-tls-verify: true' ${KUBECONFIG}
                    '''
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
                    // Confirm the app pod is running and service/ingress are ready
                    sh '''
                        kubectl --insecure-skip-tls-verify=true -n flask-project get pods
                        kubectl --insecure-skip-tls-verify=true -n flask-project get svc
                        kubectl --insecure-skip-tls-verify=true -n flask-project get ingress
                    '''
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