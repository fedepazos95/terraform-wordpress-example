include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///cloudposse/ecs-web-app/aws?version=2.1.0"
}

locals {
  env    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

dependency "vpc" {
  config_path = "../../../networking/vpc"
  mock_outputs = {
    vpc_id                        = "dummy-vpc-id"
    vpc_default_security_group_id = "dummy-default-security-group-id"
  }
}

dependency "subnets" {
  config_path = "../../../networking/subnets"
  mock_outputs = {
    private_subnet_ids = []
  }
}

dependency "alb" {
  config_path = "../../../networking/alb/ecs-cluster"
  mock_outputs = {
    alb_arn_suffix    = "dummy-arn-sufix"
    security_group_id = "dummy-security-group-id"
    listener_arns     = []
  }
}

dependency "cluster" {
  config_path = "../../cluster"
  mock_outputs = {
    arn  = "dummy-cluster-arn"
    name = "dummy-cluster-name"
  }
}

dependency "media_bucket" {
  config_path = "../../../data-storage/s3/media-storage"
  mock_outputs = {
    bucket_id = "dummy-bucket-id"
  }
}

dependency "media_bucket_policy" {
  config_path = "../../../iam/policies/wordpress-media-storage"
  mock_outputs = {
    policy_arn = "dummy-policy-arn"
  }
}

inputs = {
  name   = "wordpress"
  vpc_id = dependency.vpc.outputs.vpc_id

  # The following values are just to ensure lower costs during testing
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
  desired_count                      = 0

  ignore_changes_task_definition = false
  ecr_enabled                    = false
  codepipeline_enabled           = false
  webhook_enabled                = false
  badge_enabled                  = false
  ecs_alarms_enabled             = false
  autoscaling_enabled            = false

  # Container
  container_image  = "bitnami/wordpress:6.5.5"
  container_cpu    = 256
  container_memory = 512
  port_mappings = [
    {
      containerPort = 8080
      hostPort      = 8080
      protocol      = "tcp"
    }
  ]
  log_driver = "awslogs"
  healthcheck = {
    command = [
      "CMD-SHELL",
      "php -r \"if (file_get_contents('http://localhost:8080/') === FALSE) exit(1);\""
    ],
    interval    = 30,
    timeout     = 20,
    retries     = 3,
    startPeriod = 60
  }
  container_environment = [
    {
      name  = "WORDPRESS_DATABASE_HOST"
      value = "staging-wordpress-db.cluster-c7iqyce66u9z.us-east-2.rds.amazonaws.com"
    },
    {
      name  = "WORDPRESS_DATABASE_NAME"
      value = "wordpress"
    },
    {
      name  = "WORDPRESS_DATABASE_USER"
      value = "wordpress"
    },
    {
      name  = "WORDPRESS_PLUGINS"
      value = "amazon-s3-and-cloudfront"
    },
    {
      name  = "WORDPRESS_EXTRA_WP_CONFIG_CONTENT"
      value = <<EOF
      define('AS3CF_SETTINGS', serialize(array(
        'provider' => 'aws',
        'use-server-roles' => true,
        'bucket' => '${dependency.media_bucket.outputs.bucket_id}',
        'region' => '${local.region.locals.aws_region}',
        'copy-to-s3' => true,
        'serve-from-s3' => true
      )));
      EOF
    },
  ]
  secrets = [
    {
      name      = "WORDPRESS_DATABASE_PASSWORD",
      valueFrom = "arn:aws:ssm:us-east-2:960673230763:parameter/staging/applications/wordpress/db_password"
    }
  ]
  task_policy_arns = [
    dependency.media_bucket_policy.outputs.policy_arn
  ]

  # ECS
  ecs_private_subnet_ids = dependency.subnets.outputs.private_subnet_ids
  ecs_cluster_arn        = dependency.cluster.outputs.arn
  ecs_cluster_name       = dependency.cluster.outputs.name
  container_port         = 8080

  # ALB
  alb_arn_suffix                                  = dependency.alb.outputs.alb_arn_suffix
  alb_security_group                              = dependency.alb.outputs.security_group_id
  alb_ingress_unauthenticated_listener_arns       = dependency.alb.outputs.listener_arns
  alb_ingress_unauthenticated_listener_arns_count = 1
  alb_ingress_unauthenticated_paths               = ["/*"]
  alb_ingress_listener_unauthenticated_priority   = 100
  alb_ingress_healthcheck_path                    = "/"
  use_alb_security_group                          = true
  health_check_grace_period_seconds               = 180
  alb_ingress_health_check_interval               = 30
  alb_ingress_health_check_timeout                = 20

  tags = local.env.locals.tags
}
