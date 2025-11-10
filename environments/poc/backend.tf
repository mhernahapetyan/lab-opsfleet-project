terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.20.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.9.0"
    }
    kubernetes = {
        source  = "hashicorp/kubernetes"
        version = ">= 2.20"
    }
    kubectl = {
        source  = "gavinbunney/kubectl"
        version = "1.10.1"
    }
  }

  backend "s3" {
    bucket         = "opsfleet-terraform-state-files"
    key            = "terraform/states/poc.tfstate"
    dynamodb_table = "terraform-state-lock-dynamo"
    region         = "eu-central-1"
  }
}