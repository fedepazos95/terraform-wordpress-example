include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///cloudposse/dynamic-subnets/aws?version=2.4.2"
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "dummy-vpc-id"
    igw_id = "dummy-igw-id"
  }
}

inputs = {
  name                = "wordpress-example"
  availability_zones  = ["us-east-2a", "us-east-2b", "us-east-2c"]
  vpc_id              = dependency.vpc.outputs.vpc_id
  igw_id              = [dependency.vpc.outputs.igw_id]
  cidr_block          = local.env.locals.cidr_block
  nat_gateway_enabled = true

  tags = local.env.locals.tags
}
