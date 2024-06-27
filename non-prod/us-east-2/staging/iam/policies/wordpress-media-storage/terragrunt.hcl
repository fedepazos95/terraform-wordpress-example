include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///cloudposse/iam-policy/aws?version=2.0.1"
}

locals {
  env     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  account = read_terragrunt_config(find_in_parent_folders("account.hcl"))
}

dependency "media_bucket" {
  config_path = "../../../data-storage/s3/media-storage"
  mock_outputs = {
    bucket_arn = "dummy-bucket-arn"
  }
}

inputs = {
  iam_policy_enabled = true
  iam_policy = [{
    version   = "2012-10-17"
    policy_id = "wordpress-media-storage"
    statements = [
      {
        sid    = "ListMyBucket"
        effect = "Allow"
        actions = [
          "s3:GetObject*",
          "s3:PutObject*",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucket*",
        ]
        resources = [
          "${dependency.media_bucket.outputs.bucket_arn}",
          "${dependency.media_bucket.outputs.bucket_arn}/*"
        ]
      }
    ]
  }]
}
