# Outputs file
output "public_ip_address" {
  value       = aws_instance.ec2_instance.public_ip
  description = "Public IP address of the instance"
}

output "vote_app_url" {
  value       = "http://${aws_instance.ec2_instance.public_dns}:8008"
  description = "Vote APP URL"
}

output "result_app_url" {
  value       = "http://${aws_instance.ec2_instance.public_dns}:8081"
  description = "Result APP URL"
}

output "prometheus_url" {
  value       = "http://${aws_instance.ec2_instance.public_dns}/prometheus"
  description = "Prometheus URL"
}

output "alertmanager_url" {
  value       = "http://${aws_instance.ec2_instance.public_dns}/alertmanager"
  description = "Alertmanager URL"
}

output "grafana_url" {
  value       = "http://${aws_instance.ec2_instance.public_dns}/grafana"
  description = "Grafana URL"
}