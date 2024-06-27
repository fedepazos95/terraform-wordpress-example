include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///cloudposse/alb/aws?version=1.11.1"
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "vpc" {
  config_path = "../../vpc"
  mock_outputs = {
    vpc_id                        = "dummy-vpc-id"
    vpc_default_security_group_id = "dummy-default-security-group-id"
  }
}

dependency "subnets" {
  config_path = "../../subnets"
  mock_outputs = {
    public_subnet_ids = []
  }
}

inputs = {
  vpc_id                            = dependency.vpc.outputs.vpc_id
  security_group_ids                = [dependency.vpc.outputs.vpc_default_security_group_id]
  subnet_ids                        = dependency.subnets.outputs.public_subnet_ids
  internal                          = false
  http_enabled                      = true
  http2_enabled                     = true
  access_logs_enabled               = false
  cross_zone_load_balancing_enabled = true
  deletion_protection_enabled       = false

  tags = local.env.locals.tags
}
