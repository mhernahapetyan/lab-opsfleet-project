module "iam_assumable_role_karpenter" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.7.0"
  create_role                   = true
  role_name                     = "karpenter-controller-${var.env}"
  provider_url                  = var.eks_oidc_provider_url
  oidc_fully_qualified_subjects = ["system:serviceaccount:karpenter:karpenter"]
}



resource "aws_iam_role_policy" "karpenter_controller" {
  name = "karpenter-policy"
  role = module.iam_assumable_role_karpenter.iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = var.karpenter_policy_actions
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = "iam:PassRole",
        Resource = "${aws_iam_role.instance_role.arn}",
        Sid      = "PassNodeIAMRole"
      },
      {
        Effect   = "Allow"
        Action   = var.kms_actions
        Resource = "*"
        Condition = {
          StringLike = {
            "kms:ViaService" : var.kms_via_service
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "instance_role" {
  name = "KarpenterNodeRole-agmatix-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole",
      },
    ],
  })
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "KarpenterNodeRole-agmatix"
  role = aws_iam_role.instance_role.name
}

resource "aws_iam_policy_attachment" "ssm_managed_instance_core" {
  name       = "ssm-managed-instance-core-attachment"
  roles      = [aws_iam_role.instance_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy_attachment" "ebs_csi_driver_policy" {
  name       = "ebs-csi-driver-policy-attachment"
  roles      = [aws_iam_role.instance_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_iam_policy_attachment" "eks_worker_node_policy" {
  name       = "eks-worker-node-policy-attachment"
  roles      = [aws_iam_role.instance_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_policy_attachment" "eks_cni_policy" {
  name       = "eks-cni-policy-attachment"
  roles      = [aws_iam_role.instance_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_policy_attachment" "ecr_read_only" {
  name       = "ecr-read-only-attachment"
  roles      = [aws_iam_role.instance_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy" "node_additional" {
  name = "karpenter-node-additional"
  role = aws_iam_role.instance_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:CreateTags"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_eks_access_entry" "cluster_admin" {
  cluster_name  = var.eks_cluster_name
  principal_arn = aws_iam_role.instance_role.arn
  type          = "STANDARD"
}

# Associate with cluster-admin permissions
resource "aws_eks_access_policy_association" "cluster_admin_policy" {
  cluster_name  = var.eks_cluster_name
  principal_arn = aws_iam_role.instance_role.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.cluster_admin]
}