"""Lambda 3: Custom privileged IAM action checker.

Triggered by SNS Topic 1: iam-policy-evaluation-events.
Reads privileged-actions.txt from S3 and checks whether the policy grants any listed action.
Publishes findings to SNS Topic 2: security-alerts.
"""
import json
import logging
import os

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
BUCKET = os.environ["BUCKET"]
KEY = os.environ["KEY"]

s3 = boto3.client("s3")
sns = boto3.client("sns")
access_analyzer = boto3.client("accessanalyzer")


def load_privileged_actions():
    response = s3.get_object(Bucket=BUCKET, Key=KEY)
    content = response["Body"].read().decode("utf-8")
    return [
        line.strip()
        for line in content.splitlines()
        if line.strip() and not line.strip().startswith("#")
    ]


def lambda_handler(event, context):
    logger.info("Raw Event: %s", json.dumps(event, default=str))

    parsed_event = json.loads(event["Records"][0]["Sns"]["Message"])
    policy_document_json = json.dumps(parsed_event["policy_document"])

    privileged_actions = load_privileged_actions()
    logger.info("Loaded privileged actions count: %s", len(privileged_actions))

    results = []

    for action in privileged_actions:
        response = access_analyzer.check_access_not_granted(
            policyDocument=policy_document_json,
            policyType="IDENTITY_POLICY",
            access=[{"actions": [action]}],
        )

        # FAIL means the policy DOES grant the action being checked.
        if response.get("result") == "FAIL":
            results.append({"action": action, "reasons": response.get("reasons", [])})

    logger.info("Privileged action match count: %s", len(results))

    if not results:
        return {"status": "no_privileged_access"}

    message = (
        f"Custom Privileged IAM Action Detected\n\n"
        f"Policy Reference: {parsed_event.get('policy_reference')}\n\n"
        f"Trigger: {parsed_event.get('trigger')}\n\n"
        f"Changed By: {parsed_event.get('agent_role_arn')}\n\n"
        f"Event Time: {parsed_event.get('event_time')}\n\n"
        f"Target Principal: {parsed_event.get('target_principal')}\n\n"
        f"Source IP: {parsed_event.get('source_ip')}\n\n"
        f"Matched Privileged Actions:\n{json.dumps(results, indent=4, default=str)}\n\n"
        f"Policy Document:\n{json.dumps(parsed_event['policy_document'], indent=4)}"
    )

    response = sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=message,
        Subject="Privileged IAM Action Detected",
    )
    logger.info("SNS publish successful: %s", json.dumps(response, default=str))

    return {"status": "alert_sent", "matched_actions": len(results)}
