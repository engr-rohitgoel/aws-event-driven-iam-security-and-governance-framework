# Event-Driven IAM Governance on AWS

This Terraform project deploys an event-driven IAM governance solution:

1. IAM API calls are captured by CloudTrail and matched by EventBridge.
2. EventBridge invokes Lambda 1: `iam-policy-change-audit`.
3. Lambda 1 retrieves/normalizes the IAM policy document and publishes it to SNS Topic 1: `iam-policy-evaluation-events`.
4. SNS Topic 1 fans out to:
   - Lambda 2: `iam-policy-validator`, which runs IAM Access Analyzer `ValidatePolicy`.
   - Lambda 3: `iam-privileged-action-checker`, which checks policy access against `privileged-actions.txt` in S3.
5. Lambda 2 and Lambda 3 publish final alerts to SNS Topic 2: `security-alerts`.
6. IAM Access Analyzer unused access findings are sent to Lambda 4 by EventBridge.
7. Lambda 4 publishes final unused-access alerts to SNS Topic 2: `security-alerts`.

## Required change before apply

Copy `terraform.tfvars.example` to `terraform.tfvars` and update your email:

```hcl
region      = "us-east-1"
alert_email = "your-email@example.com"
```

Then run:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

After apply, confirm the SNS email subscription sent by AWS SNS.

## Notes

- Lambda 3 timeout is set to 120 seconds because it calls Access Analyzer once per privileged action.
- Lambda 4 is event-driven for new/updated Access Analyzer findings. Existing findings can be tested manually from the Lambda console using a real finding ID.
- The IAM permission for `get_finding_v2()` is `access-analyzer:GetFinding`, not `access-analyzer:GetFindingV2`.
