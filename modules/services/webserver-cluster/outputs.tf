output "public_ip" {
	value = aws_instance.example.public_ip
	description = "The public IP address of the	web server"
}

output "alb_dns_name" {
  value = aws_lb.example.dns_name
  description = "The domain name of the load balancer"
}

# Определяем выходную переменную ASG для дальнейшего использования
output "asg_name" {
	value = aws_autoscaling_group.example.name
	description = "The name of the Auto Scaling Group"
}

# Определяем выходную переменную для дальнейшего использования
output "alb_security_group_id" {
	value = aws_security_group.alb.id
	description = "The ID of the Security Group attached to the load balancer"
}
