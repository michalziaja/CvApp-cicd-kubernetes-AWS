
output "host_public_ip" {
  description = "host public IP"
  value       = aws_instance.ec2.public_ip
}