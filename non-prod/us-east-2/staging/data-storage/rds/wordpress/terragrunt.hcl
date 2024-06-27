include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///cloudposse/rds-cluster/aws?version=1.10.1"
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "vpc" {
  config_path = "../../../networking/vpc"
  mock_outputs = {
    vpc_id                      = "dummy-vpc-id"
    database_subnet_group_name  = "dummy-database-subnet-group-name"
    private_subnets_cidr_blocks = []
  }
}

dependency "subnets" {
  config_path = "../../../networking/subnets"
  mock_outputs = {
    private_subnet_ids = []
  }
}

dependency "admin_password" {
  config_path = "../../../system-manager/parameters/wordpress_admin_password"
  mock_outputs = {
    values = ["dummy_password"]
  }
}

dependency "wordpress" {
  config_path = "../../../ecs/services/wordpress"
  mock_outputs = {
    ecs_service_security_group_id = "dummy-security-group-id"
  }
}

inputs = {
  name           = "wordpress-db"
  engine         = "aurora-mysql"
  engine_mode    = "serverless"
  engine_version = "5.7.mysql_aurora.2.11.4"
  cluster_family = "aurora-mysql5.7"
  cluster_size   = 0
  admin_user     = "root"
  admin_password = one(dependency.admin_password.outputs.values)
  db_name        = "main"
  db_port        = 3306
  vpc_id         = dependency.vpc.outputs.vpc_id
  security_groups = [
    # Wordpress ECS Service
    dependency.wordpress.outputs.ecs_service_security_group_id,
  ]
  subnets              = dependency.subnets.outputs.private_subnet_ids
  enable_http_endpoint = true

  tags = local.env.locals.tags
}
