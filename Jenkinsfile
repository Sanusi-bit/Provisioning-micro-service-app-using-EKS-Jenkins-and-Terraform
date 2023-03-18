#!/usr/bin/env groovy
pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION = "us-west-2"
    }
    stages {
        stage("Create an EKS Cluster") {
            steps {
                script {
                    dir('terraform') {
                        sh "terraform init"
                        sh "terraform apply -auto-approve"
                    }
                }
            }
        }
        stage("Deploy the voting app to EKS") {
            steps {
                script {
                    dir('kubernetes') {
                        sh "aws eks --region eu-west-2 update-kubeconfig --name sanusibit-eks-cluster"
                        sh "kubectl apply -f db-deployment.yml"
                        sh "kubectl apply -f db-service.yml"
                        sh "kubectl apply -f redis-deployment.yml"
                        sh "kubectl apply -f redis-service.yml"
                        sh "kubectl apply -f result-deployment.yml"
                        sh "kubectl apply -f result-service.yml"
                        sh "kubectl apply -f vote-deployment.yml"
                        sh "kubectl apply -f vote-service.yml"
                        sh "kubectl apply -f worker-deployment.yml"
                        sh "kubectl apply -f secrets.yml"
                    }
                }
            }
        }
        stage("Deploy sock shop to EKS Cluster") {
            steps {
                script {
                    dir('kubernetes') {
                        sh "kubectl create namespace sock-shop"
                        sh "kubectl apply -f complete-demo.yaml"
                    }
                }
            }
        }
    }
}
