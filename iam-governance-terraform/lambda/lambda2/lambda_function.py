"""Lambda 2: IAM policy validator.

Triggered by SNS Topic 1: iam-policy-evaluation-events.
Uses IAM Access Analyzer validate_policy and publishes findings to SNS Topic 2: security-alerts.
"""
import json
import logging
import os

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]

access_analyzer = boto3.client("accessanalyzer")
sns = boto3.client("sns")


def lambda_handler(event, context):
    logger.info("Raw Event: %s", json.dumps(event, default=str))

    parsed_event = json.loads(event["Records"][0]["Sns"]["Message"])
    policy_document = parsed_event["policy_document"]

    result = access_analyzer.validate_policy(
        policyDocument=json.dumps(policy_document),
        policyType="IDENTITY_POLICY",
        locale="EN",
    )

    findings = result.get("findings", [])
    logger.info("Access Analyzer finding count: %s", len(findings))

    if not findings:
        return {"status": "no_findings"}

    message = (
        f"Access Analyzer Policy Validation Finding\n\n"
        f"Policy Reference: {parsed_event.get('policy_reference')}\n\n"
        f"Trigger: {parsed_event.get('trigger')}\n\n"
        f"Changed By: {parsed_event.get('agent_role_arn')}\n\n"
        f"Event Time: {parsed_event.get('event_time')}\n\n"
        f"Target Principal: {parsed_event.get('target_principal')}\n\n"
        f"Source IP: {parsed_event.get('source_ip')}\n\n"
        f"Policy Document:\n{json.dumps(policy_document, indent=4)}\n\n"
        f"Findings:\n{json.dumps(findings, indent=4, default=str)}"
    )

    response = sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=message,
        Subject="IAM Policy Validation Finding",
    )
    logger.info("SNS publish successful: %s", json.dumps(response, default=str))

    return {"status": "alert_sent", "finding_count": len(findings)}
