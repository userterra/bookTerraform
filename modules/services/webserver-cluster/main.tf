provider "aws" {
	#access_key = "AKIAYCBQJGVQWDFOJLOO"
	#secret_key = "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"
	region = "us-east-2"
}

locals {
		http_port = 80
		any_port = 0
		any_protocol = "-1"
		tcp_protocol = "tcp"
		all_ips = ["0.0.0.0/0"]
}


resource "aws_instance" "example" {
	ami     = "ami-0c55b159cbfafe1f0"
	instance_type  = var.instance_type
	vpc_security_group_ids = [aws_security_group.instance.id]

	#user_data = <<-EOF
 #!/bin/bash
 #echo "Hello, World" > index.html
 #nohup busybox httpd -f -p ${var.server_port}
 #EOF

 user_data = data.template_file.user_data.rendered

	tags = {
	   Name = "${var.cluster_name}-instance"
	}
}

resource "aws_security_group" "instance" {
    name = "${var.cluster_name}-instance"

		#ingress {
		#  from_port = var.server_port
		#  to_port = var.server_port
		#  protocol = "tcp"
		#  cidr_blocks = ["0.0.0.0/0"]
		#}
}


resource "aws_security_group_rule" "allow_server_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instance.id

  from_port   = var.server_port
  to_port     = var.server_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips

}



resource "aws_launch_configuration" "example" {
	image_id = "ami-0c55b159cbfafe1f0"
	instance_type = var.instance_type
	security_groups = [aws_security_group.instance.id]
	user_data = data.template_file.user_data.rendered
	#user_data = templatefile("${path.module}/user-data.sh", {
	#    server_port = var.server_port
	#    db_address  = data.terraform_remote_state.db.outputs.address
	#    db_port     = data.terraform_remote_state.db.outputs.port
  #})

	# Требуется при использовании группы	автомасштабирования
	# в конфигурации запуска.
	# https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
	lifecycle {
		create_before_destroy = true
	}
}

resource "aws_autoscaling_group" "example" {
	launch_configuration =	aws_launch_configuration.example.name
	vpc_zone_identifier = data.aws_subnets.default.ids
	target_group_arns =	[aws_lb_target_group.asg.arn]
	health_check_type = "ELB"

	min_size = var.min_size
	max_size = var.max_size

	tag {
	  key = "Name"
		value = "${var.cluster_name}-asg"
		propagate_at_launch = true
	}

}

#Запрашиваем данные от провайдера
data "aws_vpc" "default" {
		default = true
}

#Запрашиваем атрибут vpc.id
data "aws_subnets" "default" {
		#vpc_id = data.aws_vpc.default.id
		filter {
	    name   = "vpc-id"
	    values = [data.aws_vpc.default.id]
  }
}

#Создание балансировщика нагрузки ALB
resource "aws_lb" "example" {
	name = "${var.cluster_name}-asg"
	load_balancer_type = "application"
	subnets = data.aws_subnets.default.ids
	security_groups = [aws_security_group.alb.id]
}

# определение прослушивателя для	этого ALB
resource "aws_lb_listener" "http" {
	load_balancer_arn = aws_lb.example.arn
	port = local.http_port
	protocol = "HTTP"
# По умолчанию возвращает простую страницу с кодом 404
	default_action {
			type = "fixed-response"
			fixed_response {
				content_type = "text/plain"
				message_body = "404: page not found"
				status_code = 404
			}
		}
}

#создание новой группы безопасности специально для	балансировщика нагрузки
resource "aws_security_group" "alb" {
	name = "${var.cluster_name}-alb"
}

# Вложенный блок для разрешения всех входящих HTTP-запросы
resource "aws_security_group_rule" "allow_http_inbound" {
		type = "ingress"
		security_group_id = aws_security_group.alb.id
		#security_group_id = aws_security_group.instance.id

		from_port = local.http_port
		to_port = local.http_port
		protocol = local.tcp_protocol
		cidr_blocks = local.all_ips
}
# Вложенный блок для разрешения всех изходящих HTTP-запросы
resource "aws_security_group_rule" "allow_all_outbound" {
		type = "egress"
		security_group_id = aws_security_group.alb.id

		from_port = local.any_port
		to_port = local.any_port
		protocol = local.any_protocol
		cidr_blocks = local.all_ips
}


#создаем целевую группу для ASG
resource "aws_lb_target_group" "asg" {
	name = "${var.cluster_name}-asg"
	port = var.server_port
	protocol = "HTTP"
	vpc_id = data.aws_vpc.default.id

	health_check {
		path = "/"
		protocol = "HTTP"
		matcher = "200"
		interval = 15
		timeout = 3
		healthy_threshold = 2
		unhealthy_threshold = 2
	}
}

#Собираем все воедино
#Создадем правила прослушивателя
resource "aws_lb_listener_rule" "asg" {
	listener_arn = aws_lb_listener.http.arn
	priority = 100

	condition {
    path_pattern {
      values = ["*"]
    }
	}

	action {
		type = "forward"
		target_group_arn =	aws_lb_target_group.asg.arn
	}
}

data "terraform_remote_state" "db" {
	backend = "s3"
	config = {
		#bucket = "terraform-my-testing-state-2"
		bucket = var.db_remote_state_bucket
		#key = "stage/data-stores/mysql/terraform.tfstate"
    key = var.db_remote_state_key
		region = "us-east-2"
	}
}

data "template_file" "user_data" {
	# Задаем путь к файлу относительно самого модуля
		template = file("${path.module}/user-data.sh")

		vars = {
			server_port = var.server_port
			db_address = data.terraform_remote_state.db.outputs.address
			db_port = data.terraform_remote_state.db.outputs.port
		}
}
