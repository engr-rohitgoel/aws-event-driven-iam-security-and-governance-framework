# aws-event-driven-iam-security-and-governance-framework

Modern AWS environments often contain hundreds of IAM users, roles, groups, and policies. While IAM Access Analyzer helps identify overly permissive policies and unused permissions, organizations frequently need additional governance controls tailored to their own security standards.

This project implements an event-driven IAM governance framework using AWS native services to continuously monitor IAM policy lifecycle events, validate policies against AWS best practices, enforce organization-specific privileged action controls, and monitor unused IAM permissions.

The solution is fully automated using Terraform and leverages EventBridge, CloudTrail, Lambda, SNS, S3, and IAM Access Analyzer.
