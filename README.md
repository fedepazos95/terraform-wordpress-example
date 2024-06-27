# Terraform Wordpress Example

This repository outlines the process to deploy a WordPress site on AWS ECS using the Bitnami WordPress Docker image, ensuring media files are stored in AWS S3 by using WP Offload Media plugin.

## Prerequisites

- AWS Account
- AWS CLI configured
- Terraform installed
- Terragrunt installed
- Docker installed
- Parameter Store parameters

### Parameter Store
Before deploying the infrastructure, it is necessary to create parameters in AWS Systems Manager Parameter Store. These parameters will be used by RDS and ECS to configure the database access passwords.

1. Open your terminal.
1. Use the following AWS CLI commands to create the parameters:
```bash
# Create the database admin password
aws ssm put-parameter --name "/staging/databases/wordpress/admin_password" --value "your_admin_password" --type "SecureString"

# Create the database wordpress user's password
aws ssm put-parameter --name "/staging/applications/wordpress/db_password" --value "your_db_password" --type "SecureString"
```
Replace `your_admin_password` and `your_db_password` with your actual database passwords.

By setting up these parameters, we ensure secure management of sensitive information, such as database passwords, without hardcoding them in Terraform.

## Terraform Setup

The repository is structured to facilitate the management of infrastructure using Terraform modules and Terragrunt to maintain DRY (Don't Repeat Yourself) principles.

- Divided into non-prod and prod directories to separate non-production and production environments.
- Each directory contains subdirectories for different regions (e.g., us-west-2, eu-west-1), each with its own Terragrunt configuration files.

### Directory Structure
```
.
├── non-prod
│   ├── us-east-2
│   │   ├── staging
│   │   │   └── <aws-service-name>
│   │   │   │   └── <aws-resource>
│   │   │   │   │   └── terragrunt.hcl 
│   │   │   └── env.hcl
│   │   ├── qa
│   │   │   └── <aws-service-name>
│   │   │   │   └── <aws-resource>
│   │   │   │   │   └── terragrunt.hcl 
│   │   │   └── env.hcl
│   │   └── region.hcl
│   └── account.hcl
└── README.md
```

By organizing the repository in this manner, we ensure a clean, maintainable, and scalable infrastructure setup that leverages the power of Terragrunt for efficient infrastructure management.

### Deployment
To deploy the infrastructure, follow these steps:

1. Navigate to the Environment Directory

2. Execute the following command to apply all configurations for that environment
```bash
cd non-prod/us-east-2/staging
terragrunt apply-all
```

This command will initialize and apply all the Terraform configurations for the specified environment and region, setting up the necessary infrastructure as defined in the Terraform modules and configurations.

## Wordpress Setup
### WordPress Execution
- **Image:** WordPress is being executed using the Bitnami WordPress Docker image.
- **Service:** It is created as an ECS Fargate service.
- **Configuration:** The service is configured using environment variables defined in the ECS task definition.

### WP Offload Media Plugin Lite
- **Installation:** The WP Offload Media Plugin Lite is installed automatically via the `WORDPRESS_PLUGINS` environment variable.
- **Configuration:** By default, the plugin is configured to offload media files to the S3 bucket created during the Terraform setup.

> The WP Offload Media Plugin could not be installed using Composer because it requires a paid license. The Lite version, which is free, is not available through Composer and must be installed manually or via the WORDPRESS_PLUGINS environment variable as done in this setup.

## Spinning Up WordPress
By default, the WordPress service is created in a disabled state because some initial configurations are required before starting the service.

**1. Access the RDS Database:**
Connect to your RDS MySQL instance using a MySQL client. You can do this from your local machine or an EC2 instance that has network access to the RDS instance.

**2. Create the WordPress Database and User:**
Run the following commands to create the WordPress database and user, and grant the necessary permissions:
```sql
-- Connect to your RDS MySQL instance
mysql -h <rds-endpoint> -u <master-username> -p

-- Create the WordPress database
CREATE DATABASE wordpress;

-- Create the WordPress user
CREATE USER 'wordpress' IDENTIFIED BY 'wordpress-pass';

-- Grant the necessary permissions to the WordPress user
GRANT ALL PRIVILEGES ON wordpress.* TO wordpress;

-- Apply the changes
FLUSH PRIVILEGES;
```
Replace `<rds-endpoint>`, `<master-username>`, and `wordpress-pass` with your actual RDS endpoint, master username, and Wordpress password.

**3. Start the WordPress Service:**
After the database and user have been created and configured, navigate to the appropriate environment directory, modify the `desired_count` value and apply the changes:

```hcl
inputs = {
  name   = "wordpress"
  vpc_id = dependency.vpc.outputs.vpc_id

  # The following values are just to ensure lower costs during testing
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
---> desired_count                   = 1
...
```
```bash
cd non-prod/us-east-2/staging/ecs/services/wordpress
terragrunt apply
```


## Contributing
Report issues/questions/feature requests on in the [issues](https://github.com/terraform-aws-modules/terraform-aws-vpc/issues/new) section.
