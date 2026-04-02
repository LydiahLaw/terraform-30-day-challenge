output "alb_dns_name" {
  value       = module.webserver_cluster.alb_dns_name
  description = "DNS name of the load balancer"
}

output "asg_name" {
  value       = module.webserver_cluster.asg_name
  description = "Name of the autoscaling group"
}

output "blue_target_group_arn" {
  value       = module.webserver_cluster.blue_target_group_arn
  description = "ARN of the blue target group"
}

output "green_target_group_arn" {
  value       = module.webserver_cluster.green_target_group_arn
  description = "ARN of the green target group"
}