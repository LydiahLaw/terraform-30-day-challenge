## Day 17 Manual Testing

### Overview

Day 17 shifted the focus from building infrastructure to validating it. Instead of adding new resources, I worked through a structured manual testing process to verify that my existing webserver cluster behaves correctly under real conditions. This included provisioning checks, functional validation, state consistency, regression testing, and cleanup discipline.

This day made one thing clear. Running terraform apply is not proof that your infrastructure works. You need a repeatable way to test and verify behavior.

This module is defined in my standalone repository: https://github.com/LydiahLaw/terraform-aws-webserver-cluster
### What I Set Out To Do

The goal was to:

* Build a structured manual testing checklist
* Execute tests against my infrastructure
* Document results clearly
* Identify failures and fix them
* Enforce cleanup to avoid unnecessary AWS costs

### Project Structure

```bash id="r1m8zt"
Day-17-Manual-Testing/
  main.tf
  manual-test-results.md
```

This setup reuses the standalone module:

```hcl id="6x3g9y"
module "webserver_cluster" {
  source = "github.com/LydiahLaw/terraform-aws-webserver-cluster?ref=main"
}
```

### Manual Testing Checklist

#### Provisioning Verification

* Terraform init completes without errors
* Terraform validate passes
* Terraform plan shows expected resources
* Terraform apply completes successfully

<img width="1366" height="768" alt="terraform apply" src="https://github.com/user-attachments/assets/51e1fad4-d6f6-4a1f-a79c-42a9b4b871fc" />


#### Resource Correctness

* Resources visible in AWS console
* Names and tags match configuration
* Security group rules match expected setup

#### Functional Verification

* ALB DNS resolves
* Curl returns expected response
* Instances pass health checks
* ASG replaces terminated instance

#### State Consistency

* Terraform plan returns no changes after apply
* State matches deployed infrastructure

#### Regression Check

* Configuration change reflected correctly
* No unexpected changes in plan
* Plan clean after re-apply

### Test Execution And Results

#### Provisioning Tests

Test: Terraform init completes
Command: terraform init
Expected: Initialization successful
Actual: Initialization successful
Result: PASS

Test: Terraform validate passes
Command: terraform validate
Expected: Success
Actual: Success
Result: PASS

Test: Terraform plan after apply
Command: terraform plan
Expected: No changes
Actual: No changes
Result: PASS

#### Functional Tests

Test: ALB DNS resolves and returns response
Command: curl -s http://webservers-day17-alb-430036926.eu-central-1.elb.amazonaws.com
Expected: HTML response
Actual: <h1>Hello from webservers-day17 - v2</h1>
Result: PASS

Test: ASG replaces terminated instance
Command: Manual termination via AWS console
Expected: ASG launches replacement instance
Actual: New instance launched automatically
Result: PASS

<img width="1366" height="713" alt="instnace deeted" src="https://github.com/user-attachments/assets/90d808e1-ac2a-421f-96eb-235e5a63b406" />
<img width="1366" height="725" alt="instance relaunces" src="https://github.com/user-attachments/assets/755f5f9d-908a-462e-9afb-d1a60dbcee09" />



#### State Consistency

Test: Terraform plan returns clean state
Command: terraform plan
Expected: No changes
Actual: No changes
Result: PASS

#### Regression Testing

Test: Regression test using custom_tag change
Command: terraform plan
Expected: Tag updates
Actual: No changes
Result: FAIL
Fix: Identified that custom_tag is not used in tagging logic

Test: Regression test using cluster_name change
Command: terraform plan
Expected: Resource updates
Actual: Replacement required but blocked by prevent_destroy
Result: FAIL
Fix: Identified lifecycle.prevent_destroy prevents replacement of critical resources

### Cleanup Process

Test: Terraform destroy
Command: terraform destroy
Expected: All resources destroyed
Actual: Destroy failed due to prevent_destroy
Result: FAIL

Test: Cleanup after module update
Command: terraform init -upgrade and terraform destroy
Expected: All resources destroyed
Actual: Successful after refreshing module
Result: PASS

Verification:

```bash id="n7v4ks"
aws ec2 describe-instances --filters "Name=tag:ManagedBy,Values=terraform" --query "Reservations[*].Instances[*].InstanceId"
```

```bash id="f4q9lm"
aws elbv2 describe-load-balancers --query "LoadBalancers[*].LoadBalancerArn"
```

Expected result: Empty outputs

### Key Insights

* Manual testing requires structure, not guesswork
* Terraform plan is one of the most important validation tools
* Not all configuration changes result in infrastructure updates
* Lifecycle rules like prevent_destroy protect infrastructure but can block legitimate changes
* Terraform caches modules, changes require reinitialization
* Incomplete destroy operations can leave orphaned resources

### Challenges Faced

* Regression test initially failed due to unused variable
* Lifecycle.prevent_destroy blocked both updates and destroy
* Module changes not reflected due to caching
* Leftover resources required manual cleanup strategy

### Conclusion

Day 17 focused on verification and discipline rather than building. The biggest shift was understanding that infrastructure must be tested intentionally, not assumed to work. The failures encountered during testing were the most valuable part, as they revealed real-world scenarios that require careful handling.

This day reinforced that reliable infrastructure is not just built. It is tested, validated, and maintained with clear processes.
