locals {
  ###############################################################
  # Common structures
  ###############################################################
  requirements_x86_yaml = [
    {
      key      = "karpenter.sh/capacity-type"
      operator = "In"
      values   = ["spot", "on-demand"]
    },
    {
      key      = "karpenter.k8s.aws/instance-category"
      operator = "In"
      values   = ["m", "c", "r", "t"]
    },
    {
      key      = "karpenter.k8s.aws/instance-size"
      operator = "NotIn"
      values   = ["nano", "micro"]
    },
    {
      key      = "kubernetes.io/arch"
      operator = "In"
      values   = ["amd64"]
    }
  ]

  requirements_arm64_yaml = [
    {
      key      = "karpenter.sh/capacity-type"
      operator = "In"
      values   = ["spot", "on-demand"]
    },
    {
      key      = "karpenter.k8s.aws/instance-family"
      operator = "In"
      values   = ["m7g", "c7g", "r7g"]
    },
    {
      key      = "karpenter.k8s.aws/instance-size"
      operator = "NotIn"
      values   = ["nano", "micro"]
    },
    {
      key      = "kubernetes.io/arch"
      operator = "In"
      values   = ["arm64"]
    }
  ]

  block_devices_yaml = [for mapping in var.block_device_mappings : {
    deviceName = mapping.deviceName
    ebs        = mapping.ebs
  }]

  ###############################################################
  # x86 NodePool + EC2NodeClass
  ###############################################################
  node_pool_x86_yaml = yamlencode({
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "${var.eks_cluster_name}-x86"
    }
    spec = {
      template = {
        metadata = {
          labels = {
            "eks.amazonaws.com/capacityType" = "SPOT"
            "architecture"                   = "x86"
          }
        }
        spec = {
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = "${var.eks_cluster_name}-x86"
          }
          requirements = local.requirements_x86_yaml
        }
      }
      limits = {
        cpu    = var.cpu_limit
        memory = var.memory_limit
      }
      disruption = {
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter    = "30s"
        expireAfter         = "720h"
        budgets = [
          { nodes = "50%" }
        ]
      }
      weight = 10
    }
  })

  node_class_x86_yaml = yamlencode({
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "${var.eks_cluster_name}-x86"
    }
    spec = {
      instanceProfile     = aws_iam_instance_profile.instance_profile.id
      blockDeviceMappings = local.block_devices_yaml
      amiSelectorTerms = [
        { alias = "al2023@latest" }
      ]
      subnetSelectorTerms = [
        { tags = { "karpenter.sh/discovery" = var.eks_cluster_name } }
      ]
      securityGroupSelectorTerms = [
        { tags = { "karpenter.sh/discovery" = var.eks_cluster_name } }
      ]
      tags = {
        Name                     = "${var.eks_cluster_name}-x86"
        "karpenter.sh/discovery" = var.eks_cluster_name
        "Architecture"           = "x86"
        "CreatedBy"              = "terraform"
      }
    }
  })

  ###############################################################
  # ARM64 NodePool + EC2NodeClass
  ###############################################################
  node_pool_arm64_yaml = yamlencode({
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "${var.eks_cluster_name}-arm64"
    }
    spec = {
      template = {
        metadata = {
          labels = {
            "eks.amazonaws.com/capacityType" = "SPOT"
            "architecture"                   = "arm64"
          }
        }
        spec = {
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = "${var.eks_cluster_name}-arm64"
          }
          requirements = local.requirements_arm64_yaml
        }
      }
      limits = {
        cpu    = var.cpu_limit
        memory = var.memory_limit
      }
      disruption = {
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter    = "30s"
        expireAfter         = "720h"
        budgets = [
          { nodes = "50%" }
        ]
      }
      weight = 10
    }
  })

  node_class_arm64_yaml = yamlencode({
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "${var.eks_cluster_name}-arm64"
    }
    spec = {
      instanceProfile     = aws_iam_instance_profile.instance_profile.id
      blockDeviceMappings = local.block_devices_yaml
      amiSelectorTerms = [
        { alias = "al2023@latest" }
      ]
      subnetSelectorTerms = [
        { tags = { "karpenter.sh/discovery" = var.eks_cluster_name } }
      ]
      securityGroupSelectorTerms = [
        { tags = { "karpenter.sh/discovery" = var.eks_cluster_name } }
      ]
      tags = {
        Name                     = "${var.eks_cluster_name}-arm64"
        "karpenter.sh/discovery" = var.eks_cluster_name
        "Architecture"           = "arm64"
        "CreatedBy"              = "terraform"
      }
    }
  })

  ###############################################################
  # Combine both provisioners
  ###############################################################
  provisioners = {
    x86_workers = {
      node_pool  = local.node_pool_x86_yaml
      node_class = local.node_class_x86_yaml
    }
    arm64_workers = {
      node_pool  = local.node_pool_arm64_yaml
      node_class = local.node_class_arm64_yaml
    }
  }
}
