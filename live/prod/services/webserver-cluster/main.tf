provider "aws" {
    region = "us-east-2"
}

module "webserver-cluster" {
  source = "../../../modules/services/webserver-cluster"

  #cluster_name = "webservers-prod"
  #db_remote_state_bucket = "terraform-my-testing-state-2"
  #db_remote_state_key = "prod/data-stores/mysql/terraform.tfstate"

  cluster_name           = var.cluster_name
  db_remote_state_bucket = var.db_remote_state_bucket
  db_remote_state_key    = var.db_remote_state_key

  instance_type = "m4.large"
  min_size = 2
  max_size = 10
}

# Планирование увеличение кол-ва ресурсов в 9 утра каждый день
resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
    scheduled_action_name = "scale-out-during-business-hours"
    min_size = 2
    max_size = 10
    desired_capacity = 10
    # Usare parametr Cron
    recurrence = "0 9 * * *"

    autoscaling_group_name = module.webserver-cluster.asg_name
}

# Планирование уьуньшения кол-ва ресурсов в 17 вечера каждый день
resource "aws_autoscaling_schedule" "scale_in_at_night" {
    scheduled_action_name = "scale-in-at-night"
    min_size = 2
    max_size = 10
    desired_capacity = 2
    recurrence = "0 17 * * *"

    autoscaling_group_name = module.webserver-cluster.asg_name
}
