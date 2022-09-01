provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "terraform_state" {
    #bucket = "terraform-my-testing-state-2"

    # Предотвращаем случайное удаление этого     бакета S3
    lifecycle {
      prevent_destroy = true
    }

    # Включаем управление версиями, чтобы вы могли просматривать
    # всю историю ваших файлов состояния
    versioning {
      enabled = true
    }

    # Включаем шифрование по умолчанию на стороне сервера
    server_side_encryption_configuration {
      rule {
        apply_server_side_encryption_by_default {
          sse_algorithm = "AES256"
        }
      }
    }
}

resource "aws_dynamodb_table" "terraform_lock" {
    name = "terraform-app-and-running-locks-2"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"

    attribute {
      name = "LockID"
      type = "S"
    }
}

terraform {
  backend "s3" {
    #bucket = "terraform-my-testing-state-2"
    #key = "global/s3/terraform.tfstate"
    key = "stage/services/webserver-cluster/terraform.tfstate"
    #region = "us-east-2"
    #dynamodb_table = "terraform-app-and-running-locks-2"
    #encrypt = true
  }
}

# Enter in CLI for inicialization
# ATTENTION PATH ONLY "____"
# $ terraform init -backend-config="I:\Disk 1\Studiare\idtnJS\Terraform\bookTerraform\chapter3\backend.hcl"
