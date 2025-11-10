provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

provider "kubernetes" {
  host                   = var.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(var.eks_cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = var.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(var.eks_cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

provider "kubectl" {
  host                   = var.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(var.eks_cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

data "aws_eks_cluster_auth" "this" {
  name = var.eks_cluster_name
}

terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.10.0"
    }
  }
}