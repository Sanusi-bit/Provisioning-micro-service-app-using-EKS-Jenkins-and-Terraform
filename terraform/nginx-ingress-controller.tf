provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.default.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.default.token
    }
}

resource "helm_release" "nginx-ingress-controller" {
  name       = "nginx-ingress-controller"
  chart      = "nginx-ingress-controller"
  repository = "https://charts.bitnami.com/bitnami"

  set {
    name  = "autoDiscoverAwsRegion"
    value = "true"
  }
  set {
    name  = "autoDiscoverAwsVpcID"
    value = "true"
  }
  set {
    name = "service.type"
    value = "LoadBalancer"
  }
}

data "kubernetes_service" "nginx-ingress-controller" {

  metadata {
    name      = "nginx-ingress-controller"
    namespace = "voting-app"
  }
  depends_on = [
    helm_release.nginx-ingress-controller
  ]
}