pipeline {
    agent any

    environment {
        APP_NAME = "flask-app"
        IMAGE_NAME = "flask-app-image"
        REGISTRY = "nelxn"  // DockerHub username
    }

    stages {
        stage('Start Minikube') {
            steps {
                sh 'minikube start --driver=docker --cpus=2 --memory=2g'
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                dir('infra/minikube-setup') {
                    sh '''
                        terraform init
                        terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                dir('apps') {
                    sh '''
                        docker build -t $REGISTRY/$IMAGE_NAME:latest .
                        docker push $REGISTRY/$IMAGE_NAME:latest
                    '''
                }
            }
        }
    }
}
