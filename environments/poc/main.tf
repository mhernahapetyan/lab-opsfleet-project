module "vpc" {
  source = "../../modules/vpc"
  env    = var.env
  cidr   = var.cidr
}

module "eks" {
  source     = "../../modules/eks"
  cidr       = module.vpc.vpc_cidr_block
  subnet_ids = module.vpc.private_subnet_ids
  env        = var.env
  vpc_id     = module.vpc.vpc_id
}

module "karpenter" {
  source     = "../../modules/karpenter"
  eks_cluster_certificate_authority_data = module.eks.authority_data
  eks_cluster_endpoint = module.eks.cluster_endpoint
  eks_cluster_name = module.eks.cluster_name
  eks_oidc_provider_url = module.eks.oidc_provider
  env = var.env
}