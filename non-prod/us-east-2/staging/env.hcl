# Set common variables for the environment. This is automatically pulled in the root terragrunt.hcl configuration to
# feed forward to the child modules.
locals {
  environment = "staging"
  cidr_block  = "10.0.0.0/16"
  tags = {
    Terraform   = "true"
    Environment = local.environment
  }
}