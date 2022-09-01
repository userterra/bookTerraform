provider "aws" {
  region = "us-east-2"
}

# Genereted password
resource "random_string" "rds_password" {
  length           = 12
  special          = true
  override_special = "!#$&"
  keepers = {
    keeper1 = var.name # If this change, pass change also
  }
}

# Storage password
resource "aws_ssm_parameter" "rds_password" {
  name        = "/prod/mysql"
  description = "Master Password for RDS MySQL"
  type        = "SecureString"
  value       = random_string.rds_password.result
}


resource "aws_db_instance" "example" {
    identifier_prefix = "terraform-up-and-running"
    engine = "mysql"
    # Задаем размер хранилища 10GB
    allocated_storage = 10
    # Free Server with 1 CPU+1GB Memory
    instance_class = "db.t2.micro"
    db_name = "example_database"
    username = "admin"
    password             = data.aws_ssm_parameter.my_rds_password.value
}

#data "aws_secretsmanager_secret_version" "db_password" {
  #secret_id = "mysql-master-password-stage"
#}

data "aws_ssm_parameter" "my_rds_password" {
  name        = "/prod/mysql"

#Control for use after create password
  depends_on = [aws_ssm_parameter.rds_password]
}

# Storage config password in backet S3
terraform {
    backend "s3" {
# Поменяйте это на имя своего бакета!
      bucket = "terraform-my-testing-state-2"
      key = "prod/data-stores/mysql/terraform.tfstate"
      region = "us-east-2"
# Замените это именем своей таблицы DynamoDB!
      dynamodb_table = "terraform-app-and-running-locks-2"
      encrypt = true
    }
}
