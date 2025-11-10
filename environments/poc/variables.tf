variable "env" {
  type        = string
  description = "Environment name"
  default     = "poc"
}

variable "cidr" {
  type        = string
  description = "Define /16 cidr blocks for each env"
  default     = "10.20.0.0/16"
}
