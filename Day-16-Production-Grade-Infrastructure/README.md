## day-16-production-grade-infrastructure

### overview

Day 16 focused on closing the gap between working Terraform and production-grade infrastructure. Instead of building new resources, I audited my existing webserver cluster and refactored it to meet real-world standards around security, reliability, observability, and maintainability.

This involved improving my standalone module and then consuming it from this Day 16 configuration, while also introducing infrastructure testing using Terratest.



### what i set out to do

The goal for today was to take an already functional setup (ASG, ALB, launch template) and make it production-ready.

That meant:

* removing unsafe defaults
* enforcing consistent structure
* improving observability
* validating inputs
* protecting critical resources from accidental deletion


### architecture

This setup provisions:

* an application load balancer
* an auto scaling group of EC2 instances
* launch template for instance configuration
* security groups for controlled traffic flow
* CloudWatch alarms for monitoring
* SNS topic for alerting

Traffic flow:
User → ALB → Target Group → EC2 instances


### project structure

```bash
Day-16-Production-Grade-Infrastructure/
  main.tf
  tests/
    webserver_test.go
```

This configuration calls a reusable module:

```hcl
module "webserver_cluster" {
  source = "github.com/LydiahLaw/terraform-aws-webserver-cluster?ref=main"
}
```


### key improvements implemented

#### 1. centralized tagging

I introduced a common tagging strategy using locals to ensure consistency across all resources.

```hcl
locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.cluster_name
  }
}
```

All resources now use:

```hcl
tags = merge(local.common_tags, {
  Name = "resource-name"
})
```


#### 2. secure traffic flow

Previously, EC2 instances were publicly accessible. This was fixed by restricting instance access to only the ALB.

Before:

```hcl
cidr_blocks = ["0.0.0.0/0"]
```

After:

```hcl
security_groups = [aws_security_group.alb_sg.id]
```

This ensures:

* ALB is public
* EC2 instances are private


#### 3. dynamic ami selection

Removed hardcoded AMI and replaced it with a data source.

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
}
```

This makes deployments portable and future-proof.


#### 4. prevent_destroy protection

Critical resources were protected from accidental deletion.

```hcl
lifecycle {
  prevent_destroy = true
}
```

Applied to:

* load balancer
* auto scaling group
* launch template


#### 5. observability with alerts

CloudWatch alarms were extended to trigger SNS notifications.

```hcl
resource "aws_sns_topic" "alerts" {}
```

```hcl
alarm_actions = [aws_sns_topic.alerts.arn]
```

Now:

* high CPU triggers alerts
* system is observable, not silent


#### 6. input validation

Added validation rules to prevent invalid configurations.

```hcl
validation {
  condition     = contains(["dev", "staging", "production"], var.environment)
  error_message = "Invalid environment"
}
```

```hcl
validation {
  condition     = can(regex("^t[23]\\.", var.instance_type))
  error_message = "Invalid instance type"
}
```



#### 7. provider version pinning

Ensured consistent provider behavior across environments.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```



### testing with terratest

A basic Terratest was added to validate the deployment.

Location:

```bash
tests/webserver_test.go
```

What it does:

* runs terraform init and apply
* retrieves ALB DNS output
* sends HTTP request to verify response
* destroys infrastructure after test

This introduces automated validation instead of manual checks.



### how to run

#### initialize

```bash
terraform init
```

#### plan

```bash
terraform plan
```

#### apply

```bash
terraform apply
```

#### destroy (note: prevent_destroy will block some resources)

```bash
terraform destroy
```



### challenges faced

One key issue was referencing a module version that had not been pushed or tagged. Terraform failed to download the module until the changes were committed and pushed.

Another challenge was ensuring consistency between module logic and usage, especially around security groups and tagging.



### key takeaways

* working Terraform is not the same as production-ready Terraform
* small details like tagging and validation have a big impact
* security should be intentional, not default
* infrastructure should be testable, not assumed to work
* versioning modules is essential for maintainability



### conclusion

Day 16 shifted the focus from building infrastructure to engineering it properly. The changes made here ensure that the system is safer, more predictable, and easier to maintain.

This is the point where Terraform stops being just a tool and becomes part of a reliable infrastructure workflow.
