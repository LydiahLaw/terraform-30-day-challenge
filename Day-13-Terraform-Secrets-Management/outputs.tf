output "db_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.example.endpoint
  sensitive   = true
}

output "db_username" {
  description = "The master username for the RDS instance"
  value       = aws_db_instance.example.username
  sensitive   = true
}
