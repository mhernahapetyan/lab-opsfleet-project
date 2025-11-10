#################################
# variables.tf
#################################

variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "eu-central-1"
}

variable "env" {
  description = "Deployment environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs used for EKS node groups or other resources"
  type        = list(string)
}