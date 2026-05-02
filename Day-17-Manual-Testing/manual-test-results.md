Test: terraform init completes
Command: terraform init
Expected: Initialization completes successfully
Actual: Initialization completed successfully
Result: PASS

Test: terraform validate passes
Command: terraform validate
Expected: Success
Actual: Success
Result: PASS

Test: terraform plan after apply
Command: terraform plan
Expected: No changes
Actual: No changes
Result: PASS

Test: ALB DNS resolves and returns response
Command: curl -s http://webservers-day17-alb-430036926.eu-central-1.elb.amazonaws.com
Expected: HTML response with Hello message
Actual: <h1>Hello from webservers-day17 - v2</h1>
Result: PASS

Test: ASG replaces terminated instance
Command: Manual termination via AWS Console
Expected: ASG launches new instance
Actual: A new instance was immediately launched
Result: PASS 

Test: terraform plan after changes
Command: terraform plan
Expected: No changes
Actual: No changes. Your infrastructure matches the configuration.
Result: PASS 

Test: Regression test with cluster name change
Command: terraform plan
Expected: Resource updates or replacements due to name change
Actual: Plan shows multiple resource replacements, but fails due to lifecycle.prevent_destroy blocking destruction
Result: FAIL
Fix: Identified that prevent_destroy prevents replacement of critical resources, would require removing or modifying lifecycle rule to proceed

Test: Cleanup after disabling prevent_destroy
Command: terraform destroy
Expected: All resources destroyed
Actual: Destroy still failed because Terraform was using cached module with prevent_destroy
Result: FAIL
Fix: Ran terraform init -upgrade to refresh module, then destroy succeeded