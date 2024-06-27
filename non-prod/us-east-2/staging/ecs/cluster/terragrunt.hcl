include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///cloudposse/ecs-cluster/aws?version=0.6.1"
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  name                       = "fargate-cluster"
  container_insights_enabled = false
  capacity_providers_fargate = true

  tags = local.env.locals.tags
}
