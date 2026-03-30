output "alb_dns_name" {
  value       = module.webserver_cluster.alb_dns_name
  description = "DNS name of the production load balancer"
}

output "asg_name" {
  value       = module.webserver_cluster.asg_name
  description = "Name of the production autoscaling group"
}

output "cloudwatch_alarm_arn" {
  description = "CloudWatch alarm ARN (populated in production)"
  value       = module.webserver_cluster.cloudwatch_alarm_arn
}