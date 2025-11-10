module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.33.1"

  cluster_name = var.eks_cluster_name

  create_node_iam_role = false
  node_iam_role_arn    = aws_iam_role.instance_role.arn

  enable_v1_permissions = true
  create_access_entry   = false

  create_pod_identity_association = true

  # Used to attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

resource "helm_release" "karpenter" {
  namespace           = "karpenter"
  create_namespace    = true
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = var.karpenter_version
  wait                = false

  values = [
    <<-EOT
    replicas: ${var.controller_replicas}
    dnsPolicy: Default
    webhook:
      enabled: true
    settings:
      clusterName: ${var.eks_cluster_name}
      clusterEndpoint: ${var.eks_cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
      aws:
        spotAllocationStrategy: "${var.spot_allocation_strategy}"
    logLevel: info
    aws:
      defaultInstanceProfile: "${aws_iam_instance_profile.instance_profile.name}"
      enablePodENI: false
      enableENILimitedPodDensity: false
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.iam_assumable_role_karpenter.iam_role_arn}
    nodeSelector:
      node_type: system_nodes
    tolerations:
      - effect: NoSchedule
        key: node_type
        operator: Equal
        value: system_nodes
    crds:
      install: true
    EOT
  ]
}

resource "kubectl_manifest" "karpenter_node_pools" {
  for_each  = local.provisioners
  yaml_body = each.value.node_pool
  wait      = true

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_node_classes" {
  for_each  = local.provisioners
  yaml_body = each.value.node_class
  wait      = true

  depends_on = [
    helm_release.karpenter
  ]
}
