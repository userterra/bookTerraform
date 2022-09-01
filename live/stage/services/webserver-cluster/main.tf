
provider "aws" {
    region = "us-east-2"
}

module "webserver-cluster" {
  #source = "../../../modules/services/webserver-cluster"
<<<<<<< HEAD
  source = "github.com/userterra/bookTerraform//modules/services/webserver-cluster?ref=v0.0.1"
=======
  source = "github.com/userterra/bookTerraform/modules//webserver-cluster?ref=v0.0.1"
>>>>>>> aa13a63aa57bb84948af8548139f44f9085387b9

  #cluster_name = "webservers-stage"
  #db_remote_state_bucket = "terraform-my-testing-state-2"
  #db_remote_state_key = "stage/data-stores/mysql/terraform.tfstate"

  cluster_name           = var.cluster_name
  db_remote_state_bucket = var.db_remote_state_bucket
  db_remote_state_key    = var.db_remote_state_key


  instance_type = "t2.micro"
  min_size = 2
  max_size = 2
}

#Создаем правило aws_security_group_rule для добавления порта в группу
resource "aws_security_group_rule" "allow_testing_inbound" {
  type = "ingress"
  security_group_id = module.webserver-cluster.alb_security_group_id
  from_port = 55690
  to_port = 55690
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
