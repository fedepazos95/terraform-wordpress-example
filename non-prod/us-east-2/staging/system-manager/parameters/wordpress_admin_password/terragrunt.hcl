include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///cloudposse/ssm-parameter-store/aws?version=0.13.0"
}

inputs = {
  parameter_read = ["/staging/databases/wordpress/admin_password"]
}
