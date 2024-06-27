include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///cloudposse/s3-bucket/aws?version=4.2.0"
}

locals {
  env     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  account = read_terragrunt_config(find_in_parent_folders("account.hcl"))
}

inputs = {
  name                    = "${local.account.locals.aws_account_id}-wordpress-media"
  s3_object_ownership     = "BucketOwnerPreferred"
  enabled                 = true
  user_enabled            = false
  versioning_enabled      = false
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  tags = local.env.locals.tags
}
