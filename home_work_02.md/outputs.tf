# EC2 Instance Outputs
output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.demo.id
}

output "instance_public_ip" {
  description = "EC2 instance public IP"
  value       = aws_instance.demo.public_ip
}

output "instance_private_ip" {
  description = "EC2 instance private IP"
  value       = aws_instance.demo.private_ip
}

output "instance_public_dns" {
  description = "EC2 instance public DNS"
  value       = aws_instance.demo.public_dns
}

output "web_url" {
  description = "URL to access the demo web server"
  value       = "http://${aws_eip.demo.public_ip}"
}

output "elastic_ip" {
  description = "Elastic IP address"
  value       = aws_eip.demo.public_ip
}
