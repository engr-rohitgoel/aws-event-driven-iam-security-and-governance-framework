"""Lambda 1: IAM policy change audit collector.

Triggered by EventBridge CloudTrail IAM API events.
Publishes normalized policy details to SNS Topic 1: iam-policy-evaluation-events.
"""
import json
import logging
import os
from urllib.parse import unquote

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]

iam = boto3.client("iam")
sns = boto3.client("sns")


def parse_policy_document(policy_document):
    """CloudTrail can provide policyDocument as dict, JSON string, or URL-encoded JSON string."""
    if isinstance(policy_document, dict):
        return policy_document
    if isinstance(policy_document, str):
        return json.loads(unquote(policy_document))
    raise ValueError(f"Unsupported policy document type: {type(policy_document)}")


def get_policy_document(action, request_parameters):
    """Return policy reference and policy document for supported IAM API actions."""
    if action in [
        "AttachGroupPolicy",
        "AttachRolePolicy",
        "AttachUserPolicy",
        "SetDefaultPolicyVersion",
    ]:
        policy_arn = request_parameters["policyArn"]
        policy = iam.get_policy(PolicyArn=policy_arn)
        version_id = policy["Policy"]["DefaultVersionId"]
        version = iam.get_policy_version(PolicyArn=policy_arn, VersionId=version_id)
        return policy_arn, version["PolicyVersion"]["Document"]

    if action in [
        "CreatePolicy",
        "CreatePolicyVersion",
        "PutGroupPolicy",
        "PutRolePolicy",
        "PutUserPolicy",
    ]:
        policy_document = parse_policy_document(request_parameters["policyDocument"])
        policy_reference = request_parameters.get("policyArn") or request_parameters.get("policyName")
        return policy_reference, policy_document

    return None, None


def lambda_handler(event, context):
    logger.info("Raw Event: %s", json.dumps(event, default=str))

    detail = event.get("detail", {})
    action = detail.get("eventName")
    request_parameters = detail.get("requestParameters", {})

    policy_reference, policy_document = get_policy_document(action, request_parameters)

    if policy_document is None:
        logger.info("Unsupported or missing policy document for action: %s", action)
        return {"status": "ignored", "action": action}

    target = (
        request_parameters.get("roleName")
        or request_parameters.get("groupName")
        or request_parameters.get("userName")
    )

    message = {
        "policy_reference": policy_reference,
        "trigger": action,
        "agent_role_arn": detail.get("userIdentity", {}).get("arn"),
        "event_time": detail.get("eventTime"),
        "target_principal": target,
        "policy_document": policy_document,
        "aws_region": detail.get("awsRegion"),
        "source_ip": detail.get("sourceIPAddress"),
        "account_id": event.get("account"),
    }

    logger.info("Publishing IAM policy event to SNS topic: %s", SNS_TOPIC_ARN)
    response = sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=json.dumps(message, default=str),
        Subject="IAM Policy Change Detected",
    )
    logger.info("SNS publish successful: %s", json.dumps(response, default=str))

    return {
        "status": "published",
        "policy_reference": policy_reference,
        "trigger": action,
    }
