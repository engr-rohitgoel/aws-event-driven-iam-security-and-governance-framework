"""Lambda 4: IAM Access Analyzer unused access finding alert.

Triggered by EventBridge Access Analyzer Finding events.
Fetches full finding details and publishes to SNS Topic 2: security-alerts.
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

    finding_id = event["detail"].get("findingId")
    analyzer_arn = event.get("resources", [None])[0]

    if not finding_id or not analyzer_arn:
        raise ValueError("Event must include detail.findingId and resources[0] analyzer ARN")

    response = access_analyzer.get_finding_v2(analyzerArn=analyzer_arn, id=finding_id)

    message = (
        f"IAM Access Analyzer Unused Access Finding\n\n"
        f"Analyzer: {analyzer_arn}\n\n"
        f"Finding ID: {response.get('id')}\n\n"
        f"Status: {response.get('status')}\n\n"
        f"Resource Type: {response.get('resourceType')}\n\n"
        f"Finding Type: {response.get('findingType')}\n\n"
        f"Resource Owner Account: {response.get('resourceOwnerAccount')}\n\n"
        f"Created At: {response.get('createdAt')}\n\n"
        f"Updated At: {response.get('updatedAt')}\n\n"
        f"Analyzed At: {response.get('analyzedAt')}\n\n"
        f"Finding Details:\n{json.dumps(response.get('findingDetails'), indent=4, default=str)}"
    )

    publish_response = sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=message,
        Subject="IAM Unused Access Finding",
    )
    logger.info("SNS publish successful: %s", json.dumps(publish_response, default=str))

    return {"status": "alert_sent", "finding_id": finding_id}
