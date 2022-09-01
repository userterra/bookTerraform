output "rds_password" {
  value = data.aws_ssm_parameter.my_rds_password.value
  #For security parametr only true and not possible view password
  sensitive = true
}

# View adress DB
output "address" {
  value = aws_db_instance.example.address
  description = "Connect to the database at this endpoint"
}

#View port DB
output "port" {
  value = aws_db_instance.example.port
  description = "The port the database is listening on"
}
