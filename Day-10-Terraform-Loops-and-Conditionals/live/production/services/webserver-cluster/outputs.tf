output "alb_dns_name" {
  value       = module.webserver_cluster.alb_dns_name
  description = "DNS name of the production load balancer"
}

output "asg_name" {
  value       = module.webserver_cluster.asg_name
  description = "Name of the production autoscaling group"
}

output "autoscaling_policy_arns" {
  description = "Autoscaling policies created in production"
  value       = module.webserver_cluster.autoscaling_policy_arns
}