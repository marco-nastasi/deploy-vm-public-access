# Outputs file
output "public_ip_address" {
  value = "${aws_instance.docker-playground.public_ip}"
  description = "Public IP address of the instance"
}

output "vote_app_url" {
  value = "http://${aws_instance.docker-playground.public_ip}:8008"
  description = "Vote APP URL"
}

output "result_app_url" {
  value = "http://${aws_instance.docker-playground.public_ip}:8081"
  description = "Result APP URL"
}

output "prometheus_url" {
  value = "http://${aws_instance.docker-playground.public_ip}/prometheus"
  description = "Prometheus URL"
}

output "alertmanager_url" {
  value = "http://${aws_instance.docker-playground.public_ip}/alertmanager"
  description = "Alertmanager URL"
}

output "grafana_url" {
  value = "http://${aws_instance.docker-playground.public_ip}/grafana"
  description = "Grafana URL"
}
