include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///cloudposse/vpc/aws?version=2.1.1"
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  name                             = "wordpress-example-vpc"
  ipv4_primary_cidr_block          = local.env.locals.cidr_block
  assign_generated_ipv6_cidr_block = false

  tags = local.env.locals.tags
}
