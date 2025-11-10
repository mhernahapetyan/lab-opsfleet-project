## Context ##
module "context" {
  source  = "../context"
  env     = var.env
  project = "DevOps"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.0"
  name    = "${local.service_full_name}-services-vpc"
  cidr    = var.cidr

  azs = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  public_subnets = [
    cidrsubnet(var.cidr, 8, 1),
    cidrsubnet(var.cidr, 8, 2),
    cidrsubnet(var.cidr, 8, 3)
  ]

  private_subnets = [
    cidrsubnet(var.cidr, 8, 11),
    cidrsubnet(var.cidr, 8, 12),
    cidrsubnet(var.cidr, 8, 13)
  ]

  public_subnet_tags = merge(module.context.tags,
    { "kubernetes.io/cluster/eks-cluster-${var.env}" = "shared", "kubernetes.io/role/elb" = "1" }
  )
  private_subnet_tags = merge(module.context.tags,
    { "kubernetes.io/cluster/eks-cluster-${var.env}" = "shared", "kubernetes.io/role/internal-elb" = "1", "karpenter.sh/discovery" = "eks-cluster-${var.env}" }
  )

  database_subnets = [
    cidrsubnet(var.cidr, 8, 21),
    cidrsubnet(var.cidr, 8, 22),
    cidrsubnet(var.cidr, 8, 23)
  ]

  private_subnet_names  = ["net-${var.env}-private-az1", "net-${var.env}-private-az2", "net-${var.env}-private-az3"]
  public_subnet_names   = ["net-${var.env}-public-az1", "net-${var.env}-public-az2", "net-${var.env}-public-az3"]
  database_subnet_names = ["net-${var.env}-data-az1", "net-${var.env}-data-az2", "net-${var.env}-data-az3"]

  database_subnet_tags = {
    Role = "db"
  }

  # If the NAT Gateway is recreated and its Public IP changed, please make sure to update the new Public IP in the ICLink integration (INFRA-1396) 
  enable_nat_gateway   = true
  enable_dns_hostnames = true

  tags = module.context.tags
}

resource "aws_security_group" "endpoints_networking" {
  name        = "${local.service_full_name}-vpc-endpoints-sg-networking"
  description = "Allow All inbound traffic from VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.cidr}"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    "Name" : "${local.service_full_name}-vpc-endpoints-sg"
  }
}

module "endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  depends_on = [
    module.vpc
  ]
  vpc_id = module.vpc.vpc_id

  security_group_ids = [aws_security_group.endpoints_networking.id]

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = flatten([module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
      tags            = { Name = "${local.service_full_name}-services-s3-vpc-endpoint" }
    },
    dynamodb = {
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = flatten([module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
      tags            = { Name = "${local.service_full_name}-services-dynamodb-vpc-endpoint" }
    }
    ecr-api = {
      service             = "ecr.api"
      private_dns_enabled = true
      subnet_ids          = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
      tags                = { Name = "vpce-interface-${var.env}-ecr-api" }
    },
    ecr-dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
      tags                = { Name = "vpce-interface-${var.env}-ecr-dkr" }
    },
    ec2 = {
      service             = "ec2"
      private_dns_enabled = true
      subnet_ids          = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
      tags                = { Name = "vpce-interface-${var.env}-ec2" }
    },
    ssm = {
      service             = "ssm"
      private_dns_enabled = true
      subnet_ids          = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
      tags                = { Name = "vpce-interface-${var.env}-ssm" }
    }
    ec2messages = {
      service             = "ec2messages"
      private_dns_enabled = true
      subnet_ids          = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
      tags                = { Name = "vpce-interface-${var.env}-ec2messages" }
    },
    ssmmessages = {
      service             = "ssmmessages"
      private_dns_enabled = true
      subnet_ids          = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
      tags                = { Name = "vpce-interface-${var.env}-ssmmessages" }
    }
  }
}

resource "aws_ec2_tag" "this" {
  for_each    = { for idx, subnet_id in module.vpc.private_subnets : idx => subnet_id }
  resource_id = each.value
  key         = "karpenter.sh/discovery"
  value       = "eks-cluster-${var.env}"
}