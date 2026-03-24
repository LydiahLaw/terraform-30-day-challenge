# Module: webserver-cluster

A reusable Terraform module that deploys a web server cluster on AWS. It provisions a launch template, an Auto Scaling Group, an Application Load Balancer, target group, listener, and the security groups needed to wire them together.

---

## Usage
```hcl
module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  cluster_name  = "webservers-dev"
  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 4
  server_port   = 80
}
```

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | The name to use for all cluster resources | string | — | yes |
| instance_type | EC2 instance type for the cluster | string | t2.micro | no |
| min_size | Minimum number of EC2 instances in the ASG | number | — | yes |
| max_size | Maximum number of EC2 instances in the ASG | number | — | yes |
| server_port | Port the server uses for HTTP | number | 8080 | no |

---

## Outputs

| Name | Description |
|------|-------------|
| alb_dns_name | The domain name of the Application Load Balancer |
| asg_name | The name of the Auto Scaling Group |

---

## Resources created

- `aws_security_group` — instance security group and ALB security group
- `aws_launch_template` — defines the EC2 instance configuration and user data
- `aws_autoscaling_group` — maintains the desired number of instances across subnets
- `aws_lb` — Application Load Balancer distributing traffic across instances
- `aws_lb_target_group` — target group with health checks on the configured port
- `aws_lb_listener` — listens on port 80 and forwards to the target group

---

## Notes

- Deploys into the default VPC and its subnets in eu-central-1
- The AMI is Ubuntu 22.04 (ami-0cebfb1f908092578) — update if deploying to a different region
- `cluster_name` is used as a prefix for all resource names so multiple environments can be deployed without naming conflicts