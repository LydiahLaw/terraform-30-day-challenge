# Day 12: Zero-Downtime Deployments with Terraform

## Overview

Day 12 covers zero-downtime deployment techniques in Terraform. The focus is on why Terraform's default destroy-then-create behaviour causes downtime, how `create_before_destroy` reverses that order, the ASG naming problem that comes with it and how to solve it, and how to implement a blue/green deployment pattern that shifts traffic atomically at the load balancer level. The webserver cluster module is updated to v1.0.0 with lifecycle rules, instance refresh support, and blue/green target groups. A key lesson from this day: zero-downtime instance refresh requires a minimum of two instances — this was hit in practice and fixed before the final demo.

## Learning Objectives

- Understand why default Terraform replace behaviour causes downtime for ASG-backed applications
- Implement `create_before_destroy` on Launch Templates and Auto Scaling Groups
- Use `name_prefix` instead of `name` on ASGs to avoid naming conflicts during replacement
- Trigger instance refresh to replace running instances without downtime
- Understand the minimum instance count requirement for true zero-downtime
- Implement a blue/green listener rule that switches traffic with a single variable change

## Project Structure

```
Day-12-Zero-Downtime-Deployments/
└── live/
    └── dev/
        └── services/
            └── webserver-cluster/
                ├── main.tf
                └── outputs.tf
```

Module repository: [github.com/LydiahLaw/terraform-aws-webserver-cluster](https://github.com/LydiahLaw/terraform-aws-webserver-cluster) — tagged `v1.0.0`

## Concepts Covered

### Why Default Terraform Causes Downtime

When Terraform replaces a resource it cannot modify in-place, the default order is destroy then create. For an ASG this means instances are terminated before new ones exist, creating a downtime window. The `create_before_destroy` lifecycle rule reverses that order — new instances must pass health checks before old ones are terminated.

### create_before_destroy

Added to both the Launch Template and the ASG:

```hcl
resource "aws_launch_template" "web" {
  name_prefix            = "${var.cluster_name}-"
  image_id               = "ami-0cebfb1f908092578"
  instance_type          = local.instance_type
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # version: 2
              apt-get update -y
              apt-get install -y apache2
              systemctl start apache2
              systemctl enable apache2
              echo "<h1>Hello from ${var.cluster_name} - v2</h1>" > /var/www/html/index.html
              EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web" {
  name_prefix         = "${var.cluster_name}-"
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.web.arn, aws_lb_target_group.blue.arn, aws_lb_target_group.green.arn]
  health_check_type   = "ELB"
  min_size            = local.min_size
  max_size            = local.max_size

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

### The ASG Naming Problem

`create_before_destroy` requires the new ASG to exist alongside the old one briefly before the old is destroyed. AWS does not allow two ASGs with the same name simultaneously. Using `name` causes the apply to fail. Using `name_prefix` lets AWS append a unique timestamp to each ASG name, solving the conflict.

The deployed ASG name confirms this:

```
asg_name = "webservers-dev-20260404082236574800000003"
```

### Launch Template Versioning vs Launch Configuration

The book demonstrates this pattern with `aws_launch_configuration`, which is fully replaced on every change and triggers `create_before_destroy` automatically. Launch Templates version in-place — Terraform creates a new version of the same resource rather than replacing it. Running instances are not automatically replaced when user data changes.

The production solution is an instance refresh triggered after the Terraform apply:

```bash
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name $(terraform output -raw asg_name) \
  --region eu-central-1 \
  --preferences '{"MinHealthyPercentage":50}'
```

### The Minimum Instance Count Requirement

The first attempt ran with `min_size = 1`. With only one instance, the refresh terminated it before the replacement was healthy — causing 503s and 502s during the transition. This is not a Terraform bug. It is a fundamental requirement: zero-downtime refresh needs at least two instances so one can serve traffic while the other is replaced.

The fix was updating the dev locals block from:

```hcl
min_size = local.is_production ? 3 : 1
```

to:

```hcl
min_size = local.is_production ? 3 : 2
```

With two instances and `MinHealthyPercentage = 50`, the refresh keeps one instance healthy throughout. The traffic loop confirmed this — responses alternated between v1 and v2 as the ALB round-robined between the old and new instance during the transition, then settled on v2 once the refresh completed:

```
<h1>Hello from webservers-dev - v1</h1>
<h1>Hello from webservers-dev - v1</h1>
<h1>Hello from webservers-dev - v2</h1>
<h1>Hello from webservers-dev - v1</h1>
<h1>Hello from webservers-dev - v2</h1>
<h1>Hello from webservers-dev - v2</h1>
<h1>Hello from webservers-dev - v2</h1>
```

No 503s. No dropped requests. Instance refresh confirmed at 100% Successful.

<img width="1366" height="768" alt="Screenshot (1805)" src="https://github.com/user-attachments/assets/d2180fa4-2e0c-4dfd-b5e5-ed7a56866603" />

<img width="1366" height="768" alt="Screenshot (1808)" src="https://github.com/user-attachments/assets/390e04a9-dc3c-420e-a178-b85901dd9b7d" />



### Blue/Green Deployment

Two target groups — blue and green — are maintained alongside the existing web target group. A listener rule at priority 100 routes all traffic to whichever is active:

```hcl
variable "active_environment" {
  description = "Which environment is currently active: blue or green"
  type        = string
  default     = "blue"

  validation {
    condition     = contains(["blue", "green"], var.active_environment)
    error_message = "active_environment must be blue or green."
  }
}

resource "aws_lb_listener_rule" "blue_green" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = var.active_environment == "blue" ? aws_lb_target_group.blue.arn : aws_lb_target_group.green.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
```

Switching from blue to green changes one variable and runs one apply. The listener rule updates in a single API call with no instances created or destroyed:

```
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```

Both switches confirmed working in both directions with no observable interruption in the traffic loop.

## Module Changes in v1.0.0

Changes made to `terraform-aws-webserver-cluster` across Days 12 iterations:

- Added `create_before_destroy` lifecycle to `aws_launch_template`
- Changed ASG `name` to `name_prefix` to support concurrent ASG existence during replacement
- Added `create_before_destroy` lifecycle to `aws_autoscaling_group`
- Updated dev `min_size` from 1 to 2 in locals to support zero-downtime instance refresh
- Added `aws_lb_target_group.blue` and `aws_lb_target_group.green`
- Registered all three target groups in ASG `target_group_arns`
- Added `aws_lb_listener_rule.blue_green` with ternary routing
- Added `active_environment` variable with validation
- Added `blue_target_group_arn` and `green_target_group_arn` outputs

## Deployment Results

### Initial deployment

```
Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

Outputs:

alb_dns_name           = "webservers-dev-alb-1683808078.eu-central-1.elb.amazonaws.com"
asg_name               = "webservers-dev-20260404082236574800000003"
blue_target_group_arn  = "arn:aws:elasticloadbalancing:eu-central-1:835960997504:targetgroup/webservers-dev-blue-tg/af8e3b70f13f6d53"
green_target_group_arn = "arn:aws:elasticloadbalancing:eu-central-1:835960997504:targetgroup/webservers-dev-green-tg/d1b90def2702d232"
```

### Zero-downtime v1 to v2 transition

Instance refresh completed with no 503s. Responses alternated between v1 and v2 during the transition window then settled on v2.

```
| PercentageComplete  |   Status     |
|  100                |  Successful  |
```

### Blue to green switch

```
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```

### Green back to blue

```
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```

Both switches completed in under two seconds with no interruption.

## Key Takeaways

- `create_before_destroy` reverses Terraform's default destroy-then-create order but requires unique resource names to work
- `name_prefix` on ASGs is required — hardcoded `name` will cause apply failures when `create_before_destroy` is true
- Launch Templates version in-place unlike Launch Configurations — instance refresh is needed to replace running instances
- Zero-downtime instance refresh requires a minimum of two instances — with `min_size = 1` you will get 503s regardless of lifecycle configuration
- Blue/green traffic switching is a single listener rule update — one variable change, one apply, one API call
- Alternating responses during an instance refresh are not errors — they are the ALB distributing traffic across old and new instances during the transition window
