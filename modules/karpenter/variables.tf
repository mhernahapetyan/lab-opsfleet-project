variable "karpenter_version" {
  description = "Karpenter version"
  type        = string  
  default     = "1.3.1"
}

variable "env" {
  description = "The environment for the deployment (e.g., test, dev, staging)"
  type        = string
}

variable "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "eks_oidc_provider_url" {
  description = "EKS OIDC provider URL"
  type        = string
}

variable "eks_cluster_certificate_authority_data" {
  description = "EKS cluster CA data"
  type        = string
}

variable "controller_replicas" {
  description = "Number of Karpenter replicas"
  type        = number
  default     = 2
}

variable "spot_allocation_strategy" {
  description = "The spot allocation strategy to use for Karpenter. Options: price-capacity-optimized, capacity-optimized, lowest-price, diversified"
  type        = string
  default     = "price-capacity-optimized"
  
  validation {
    condition     = contains(["price-capacity-optimized", "capacity-optimized", "lowest-price", "diversified"], var.spot_allocation_strategy)
    error_message = "Valid values for spot_allocation_strategy are: price-capacity-optimized, capacity-optimized, lowest-price, diversified."
  }
}

variable "karpenter_policy_actions" {
  description = "List of actions for Karpenter IAM policy"
  type        = list(string)
  default = [
    "ssm:GetParameter",
    "ec2:DescribeImages",
    "ec2:RunInstances",
    "ec2:DescribeSubnets",
    "ec2:DescribeSecurityGroups",
    "ec2:DescribeLaunchTemplates",
    "ec2:DescribeInstances",
    "ec2:DescribeInstanceTypes",
    "ec2:DescribeInstanceTypeOfferings",
    "ec2:DescribeAvailabilityZones",
    "ec2:DeleteLaunchTemplate",
    "ec2:CreateTags",
    "ec2:CreateLaunchTemplate",
    "ec2:CreateFleet",
    "ec2:DescribeSpotPriceHistory",
    "pricing:GetProducts",
    "ec2:TerminateInstances",
    "iam:PassRole",
    "eks:DescribeCluster",
    "iam:CreateInstanceProfile",
    "iam:TagInstanceProfile",
    "iam:AddRoleToInstanceProfile",
    "iam:RemoveRoleFromInstanceProfile",
    "iam:DeleteInstanceProfile",
    "iam:GetInstanceProfile",
    "iam:GetRole",
    "iam:ListInstanceProfiles",
    "iam:ListInstanceProfileTags",
    "iam:ListRoles",
    "iam:ListRoleTags",
    "iam:UpdateInstanceProfile",
    "sqs:*",
    "ec2:*",
    "ecr:*",
    "iam:CreateServiceLinkedRole",
    "pricing:GetProducts",
    "ssm:GetParameter",
    "eks:DescribeNodegroup",
    "eks:ListNodegroups",
    "ec2:AssociateIamInstanceProfile",
    "ec2:DisassociateIamInstanceProfile",
    "ec2:ReplaceIamInstanceProfileAssociation",
    "ec2:DescribeIamInstanceProfileAssociations",
    "ec2:DescribeInstanceAttribute",
    "ec2:DescribeInstanceStatus",
    "ec2:DescribeInstanceTypes",
    "ec2:DescribeLaunchTemplateVersions",
    "ec2:DescribeNetworkInterfaces",
    "ec2:DescribeTags",
    "ec2:GetInstanceTypesFromInstanceRequirements",
    "ec2:ModifyInstanceAttribute",
    "ec2:RebootInstances",
    "ec2:RunInstances",
    "ec2:StartInstances",
    "ec2:StopInstances",
    "elasticloadbalancing:DescribeLoadBalancers",
    "elasticloadbalancing:DescribeTargetGroups",
    "elasticloadbalancing:RegisterTargets",
    "elasticloadbalancing:DeregisterTargets",
    "autoscaling:DescribeAutoScalingGroups",
    "autoscaling:DescribeLaunchConfigurations",
    "autoscaling:DescribeTags"
  ]
}

variable "kms_actions" {
  description = "List of KMS actions for IAM policy"
  type        = list(string)
  default = [
    "kms:Decrypt",
    "kms:GenerateDataKey",
    "kms:CreateGrant"
  ]
}

variable "kms_via_service" {
  description = "List of services for KMS actions"
  type        = list(string)
  default = [
    "ec2.*.amazonaws.com",
    "eks.*.amazonaws.com"
  ]
}

variable "cpu_limit" {
  description = "CPU limit for the node pool"
  type        = number
  default     = 20
}

variable "memory_limit" {
  description = "Memory limit for the node pool"
  type        = string
  default     = "100Gi"
}

variable "node_requirements" {
  description = "Requirements for Karpenter NodePool"
  type = list(object({
    key      = string
    operator = string
    values   = list(string)
  }))
  default = [
    {
      key      = "karpenter.sh/capacity-type"
      operator = "In"
      values   = ["spot", "on-demand"]
    },
    {
      key      = "karpenter.k8s.aws/instance-category"
      operator = "In"
      values   = ["m", "r", "c", "d", "t"]
    },
    {
      key      = "karpenter.k8s.aws/instance-cpu"
      operator = "In"
      values   = ["2", "4", "8", "16", "32"]
    },
    {
      key      = "kubernetes.io/arch"
      operator = "In"
      values   = ["amd64"]
    },
    {
      key      = "karpenter.k8s.aws/instance-hypervisor"
      operator = "In"
      values   = ["nitro"]
    },
    {
      key      = "karpenter.k8s.aws/instance-generation"
      operator = "Gt"
      values   = ["2"]
    }
  ]
}

variable "block_device_mappings" {
  description = "Block device mappings for Karpenter EC2 Node Class"
  type = list(object({
    deviceName = string
    ebs = object({
      volumeSize          = string
      volumeType          = string
      iops                = number
      throughput          = number
      encrypted           = bool
      deleteOnTermination = bool
    })
  }))
  default = [
    {
      deviceName = "/dev/xvda"
      ebs = {
        volumeSize          = "30Gi"
        volumeType          = "gp3"
        iops                = 3000
        throughput          = 125
        encrypted           = true
        deleteOnTermination = true
      }
    },
    {
      deviceName = "/dev/xvdb"
      ebs = {
        volumeSize          = "30Gi"
        volumeType          = "gp3"
        iops                = 3000
        throughput          = 125
        encrypted           = true
        deleteOnTermination = true
      }
    }
  ]
}