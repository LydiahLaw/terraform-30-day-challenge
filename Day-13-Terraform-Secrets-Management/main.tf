# Fetch the secret metadata
data "aws_secretsmanager_secret" "db_credentials" {
  name = "prod/db/credentials"
}

# Fetch the secret value
data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
}

# Decode the JSON string into a map
locals {
  db_credentials = jsondecode(
    data.aws_secretsmanager_secret_version.db_credentials.secret_string
  )
}

# RDS instance using credentials from Secrets Manager
resource "aws_db_instance" "example" {
  engine              = "mysql"
  engine_version      = "8.0"
  instance_class      = var.db_instance_class
  db_name             = var.db_name
  allocated_storage   = var.allocated_storage
  skip_final_snapshot = true

  username = local.db_credentials["username"]
  password = local.db_credentials["password"]
}
