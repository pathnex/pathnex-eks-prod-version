terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.2"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = aws_eks_cluster.pathnex.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.pathnex.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks", "get-token",
      "--cluster-name", aws_eks_cluster.pathnex.name,
      "--region", var.aws_region
    ]
  }
}

provider "helm" {
  kubernetes = {
    host = aws_eks_cluster.pathnex.endpoint
    cluster_ca_certificate = base64decode(
      aws_eks_cluster.pathnex.certificate_authority[0].data
    )

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"

      args = [
        "eks",
        "get-token",
        "--cluster-name",
        aws_eks_cluster.pathnex.name,
        "--region",
        "ap-south-1"
      ]
    }
  }
}
