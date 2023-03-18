#Handling the statefile and aws provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}


provider "aws" {
    region = "eu-west-2"
}

/*data "aws_eks_cluster" "default" {
  name = local.name
}

data "aws_eks_cluster_auth" "default" {
  name = local.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.default.token
}*/

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

locals {
  name= join("-", ["sanusibit", "eks","cluster"])
  vpc_name= join("-", ["sanusibit","eks", "vpc"])
  region= var.region

  vpc_cidr= "10.0.0.0/16"
  azs= slice(data.aws_availability_zones.available.names,0,2)

  tags={
    Name = local.name
    School = "Sanusibit"
  }

}
