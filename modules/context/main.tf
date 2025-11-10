locals {
  standard_tags = {
    Project   = var.project
    Env       = var.env
    CreatedBy = "terraform-${var.env}"
  }

  tags = merge(
    var.additional_tags,
    local.standard_tags,
  )
}
