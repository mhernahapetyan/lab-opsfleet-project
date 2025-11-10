

variable "project" {
  description = "to which project does it belong"
  type = string
}

variable "env" {
  type    = string
  validation {
    condition = contains(
      ["dev", "test", "staging", "demo", "prod", "infra", "poc"],
      var.env
    )
    error_message = "Environment must be one of dev, test, staging, demo, prod, poc, infra."
  }
  description = "value of environment"
}


variable "additional_tags" {
  type        = map(string)
  default     = {}
  description = "A map of additional tags to merge with the module's standard tags and apply to the resource."
}