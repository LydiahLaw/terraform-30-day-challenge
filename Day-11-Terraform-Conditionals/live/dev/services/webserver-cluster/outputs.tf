output "alb_dns_name" {
  value       = module.webserver_cluster.alb_dns_name
  description = "DNS name of the dev load balancer"
}

output "asg_name" {
  value       = module.webserver_cluster.asg_name
  description = "Name of the dev autoscaling group"
}

output "cloudwatch_alarm_arn" {
  description = "CloudWatch alarm ARN (null in dev)"
  value       = module.webserver_cluster.cloudwatch_alarm_arn
}