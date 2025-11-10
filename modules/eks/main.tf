## Context ##
module "context" {
  source  = "../context"
  env     = var.env
  project = "DevOps"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.8.0"

  name                    = "eks-cluster-${var.env}"
  kubernetes_version      = "1.34"
  endpoint_private_access = false
  endpoint_public_access  = true
  enable_irsa             = true

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  security_group_name                      = "sgr-${var.env}-eks-cluster"
  security_group_use_name_prefix           = false
  security_group_description               = "EKS Cluster security group"
  enable_cluster_creator_admin_permissions = true

  node_security_group_additional_rules = {
    ingress_all_vpc = {
      description = "!!Node all ingress from vpc!!"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      cidr_blocks = [var.cidr]
    },
    ingress_self_all = {
      description = "!!Node to node all ports/protocols!!"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }

  eks_managed_node_groups = {
    system-nodes = {
      node_group_name = "system-nodes"
      instance_types  = ["t3.medium"]
      ami_type        = "AL2023_x86_64_STANDARD"
      subnet_ids      = var.subnet_ids
      min_size        = 2 # 1 node per subnet (approx)
      max_size        = 4
      desired_size    = 2
      capacity_type   = "ON_DEMAND"

      additional_tags = {
        Name = "opsfleet-shared-eks-nodegroup-system-nodes"
      }

      launch_template_tags = {
        Name = "opsfleet-shared-eks-nodegroup-system-nodes"
      }

      instance_metadata_tags = {
        Name = "opsfleet-shared-eks-nodegroup-system-nodes"
      }

      labels = {
        node_type = "system_nodes"
      }
    }
  }
  tags = merge(module.context.tags,
    { "kubernetes.io/cluster/eks-cluster-${var.env}" = "shared", "karpenter.sh/discovery" = "eks-cluster-${var.env}" }
  )

}