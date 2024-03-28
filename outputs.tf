# Outputs file
output "public_ip_address" {
  value = "${aws_instance.docker-playground.public_ip}"
  description = "Public IP address of the instance"
}