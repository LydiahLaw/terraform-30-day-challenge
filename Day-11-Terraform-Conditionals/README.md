# Day 11: Terraform Conditionals

## Overview

Day 11 goes deep on conditional logic in Terraform. The focus is on making a single module configuration behave differently across environments without duplicating code. The webserver cluster module is updated to v0.0.4 with environment-driven sizing, optional CloudWatch monitoring, input validation, and a conditional VPC lookup pattern. Dev and production are deployed from the same module code, differentiated entirely by the `environment` variable.

## Learning Objectives

- Centralise conditional logic in locals instead of scattering ternary operators across resource arguments
- Use `count = condition ? 1 : 0` to make resources optional
- Reference conditionally created resources safely in outputs
- Add input validation to catch invalid variable values at plan time
- Use conditional data source lookups to support both greenfield and brownfield deployments

## Project Structure

```
Day-11-Terraform-Conditionals/
└── live/
    ├── dev/
    │   └── services/
    │       └── webserver-cluster/
    │           ├── main.tf
    │           └── outputs.tf
    └── production/
        └── services/
            └── webserver-cluster/
                ├── main.tf
                └── outputs.tf
```

Module repository: [github.com/LydiahLaw/terraform-aws-webserver-cluster](https://github.com/LydiahLaw/terraform-aws-webserver-cluster) — tagged `v0.0.4`

## Concepts Covered

### Locals-Centralised Conditional Logic

All conditional decisions sit in one locals block. Resources reference locals rather than evaluating conditions themselves.

```hcl
locals {
  is_production = var.environment == "production"

  instance_type     = local.is_production ? "t2.medium" : "t2.micro"
  min_size          = local.is_production ? 3 : 1
  max_size          = local.is_production ? 10 : 3
  enable_monitoring = local.is_production
}
```

If the condition string changes, you update it in one place. Every downstream decision updates automatically.

### Conditional Resource Creation

The `count = condition ? 1 : 0` pattern makes entire resources optional. When count is 0 the resource is not created. When count is 1 it is created exactly once.

```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = local.enable_monitoring ? 1 : 0

  alarm_name          = "${var.cluster_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU utilization exceeded 80%"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
}
```

### Safe Output References

When a resource uses `count = condition ? 1 : 0`, Terraform tracks it as a list. Referencing it directly in an output errors when count is 0 because the list is empty. The correct pattern guards the reference with the same condition:

```hcl
output "cloudwatch_alarm_arn" {
  description = "ARN of the high CPU alarm, null when monitoring is disabled"
  value       = local.enable_monitoring ? aws_cloudwatch_metric_alarm.high_cpu[0].arn : null
}
```

When monitoring is disabled the output returns null. When enabled it returns the ARN.

### Input Validation

The validation block runs at plan time before any API calls are made. It catches invalid values with a clear error message.

```hcl
variable "environment" {
  description = "Deployment environment: dev, staging, or production"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}
```

Passing `environment=staging2` produces:

```
Error: Invalid value for variable
  environment must be dev, staging, or production.
```

### Conditional Data Source Lookup

This pattern lets the module work in both greenfield and brownfield deployments.

```hcl
data "aws_vpc" "existing" {
  count = var.use_existing_vpc ? 1 : 0
  tags  = { Name = "existing-vpc" }
}

locals {
  vpc_id = var.use_existing_vpc ? data.aws_vpc.existing[0].id : data.aws_vpc.default.id
}
```

When `use_existing_vpc = false` the module uses the default VPC. When `use_existing_vpc = true` it looks up an existing VPC by tag. Resources downstream reference `local.vpc_id` and do not need to know which path was taken.

## Module Changes in v0.0.4

Changes made to `terraform-aws-webserver-cluster` from v0.0.3:

- Added `enable_detailed_monitoring` and `use_existing_vpc` variables
- Added validation block to the `environment` variable
- Expanded locals block to centralise all environment-based decisions including `min_size`, `max_size`, and `enable_monitoring`
- Updated ASG to use `local.min_size` and `local.max_size` instead of `var.min_size` and `var.max_size`
- Added `aws_cloudwatch_metric_alarm.high_cpu` with count conditional
- Added conditional data source for existing VPC lookup
- Added `cloudwatch_alarm_arn` output with ternary guard

## Deployment Results

### Dev (`environment = "dev"`, `enable_detailed_monitoring = false`)

```
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

alb_dns_name         = "webservers-dev-alb-112970095.eu-central-1.elb.amazonaws.com"
asg_name             = "webservers-dev-asg"
cloudwatch_alarm_arn = null
```

No CloudWatch alarm created. `cloudwatch_alarm_arn` returns null as expected.

### Production (`environment = "production"`, `enable_detailed_monitoring = true`)

```
Apply complete! Resources: 9 added, 0 changed, 0 destroyed.

Outputs:

alb_dns_name         = "webservers-production-alb-2005784647.eu-central-1.elb.amazonaws.com"
asg_name             = "webservers-production-asg"
cloudwatch_alarm_arn = "arn:aws:cloudwatch:eu-central-1:835960997504:alarm:webservers-production-high-cpu"
```

Two additional resources created compared to dev: the CloudWatch alarm and one autoscaling policy. Instance type resolved to `t2.medium` and cluster size to min 3, max 10 — all driven by `local.is_production`.

Both environments destroyed after verification.

## Key Takeaways

- Put all conditional decisions in locals. Resources should read values, not evaluate conditions
- `count = condition ? 1 : 0` is the only way to make a resource optional in Terraform
- Any output referencing a conditional resource needs a ternary guard to avoid index-out-of-range errors when count is 0
- Validation blocks are one of the most practical features for shared modules — they catch mistakes before anything is deployed
- You cannot use a conditional to choose between two resource types. Terraform resolves resource types at parse time before variables are known. Use separate resource blocks with their own count conditionals instead
