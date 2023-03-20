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
                        /*sh "kubectl create namespace voting-app"*/
                        sh "kubectl apply -f db-deployment.yml --namespace voting-app"
                        sh "kubectl apply -f db-service.yml --namespace voting-app"
                        sh "kubectl apply -f redis-deployment.yml --namespace voting-app"
                        sh "kubectl apply -f redis-service.yml --namespace voting-app"
                        sh "kubectl apply -f result-deployment.yml --namespace voting-app"
                        sh "kubectl apply -f result-service.yml --namespace voting-app"
                        sh "kubectl apply -f vote-deployment.yml --namespace voting-app"
                        sh "kubectl apply -f vote-service.yml --namespace voting-app"
                        sh "kubectl apply -f worker-deployment.yml --namespace voting-app"
                        sh "kubectl apply -f ingress-nginx.yml --namespace voting-app"
                    }
                }
            }
        }
        stage("Deploy sock shop to EKS Cluster") {
            steps {
                script {
                    dir('kubernetes') {
                        /*sh "kubectl create namespace sock-shop*/"
                        sh "kubectl apply -f complete-demo.yaml --namespace sock-shop"
                    }
                }
            }
        }
        stage("Deploy sock shop to EKS Cluster") {
            steps {
                script {
                    dir('manifests-monitoring') {
                        sh "kubectl apply -f 00-monitoring-ns.yaml"
                        sh "kubectl apply -f 01-prometheus-sa.yaml"
                        sh "kubectl apply -f 02-prometheus-cr.yaml"
                        sh "kubectl apply -f 03-prometheus-crb.yaml"
                        sh "kubectl apply -f 04-prometheus-configmap.yaml"
                        sh "kubectl apply -f 05-prometheus-alertrules.yaml"
                        sh "kubectl apply -f 06-prometheus-dep.yaml"
                        sh "kubectl apply -f 07-prometheus-svc.yaml"
                        sh "kubectl apply -f 08-prometheus-exporter-disk-usage-ds.yaml"
                        sh "kubectl apply -f 10-kube-state-sa.yaml"
                        sh "kubectl apply -f 11-kube-state-cr.yaml"
                        sh "kubectl apply -f 12-kube-state-crb.yaml"
                        sh "kubectl apply -f 13-kube-state-dep.yaml"
                        sh "kubectl apply -f 14-kube-state-svc.yaml"
                        sh "kubectl apply -f 20-grafana-configmap.yaml"
                        sh "kubectl apply -f 21-grafana-dep.yaml"
                        sh "kubectl apply -f 22-grafana-svc.yaml"
                        sh "kubectl apply -f 23-grafana-import-dash-batch.yaml"
                        sh "kubectl apply -f 24-prometheus-node-exporter-sa.yaml"
                        sh "kubectl apply -f 25-prometheus-node-exporter-daemonset.yaml"
                        sh "kubectl apply -f 26-prometheus-node-exporter-svc.yaml"
                    }
                }
            }
        }
    }
}
