module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  cluster_name  = "webservers-dev"
  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 4
  server_port   = 80
}

output "alb_dns_name" {
  value = module.webserver_cluster.alb_dns_name
}