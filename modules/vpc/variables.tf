variable "env" {
  type        = string
  description = "Environment name"
}


variable "project_name" {
  type        = string
  description = "The name of the project"
  default     = "opsfleet"
}

variable "cidr" {
  type        = string
  description = "Define /16 cidr blocks for each env"
}

variable "aws_region" {
  type        = string
  description = "Define AWS region"
  default     = "eu-central-1"
}

