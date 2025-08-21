import json
import boto3
import os
from datetime import datetime

dynamodb = boto3.resource("dynamodb")

WORKFLOW_TRACK_TABLE = os.environ.get("WORKFLOW_TABLE", "workflow_statut")


def lambda_handler(event, context):

    print("Received event:", json.dumps(event))

    workflow_table = dynamodb.Table(WORKFLOW_TRACK_TABLE)


    for record in event["Records"]:

        sqs_body = json.loads(record["body"])
        
        s3_event = sqs_body["Records"][0]
        bucket = s3_event["s3"]["bucket"]["name"]
        object_key = s3_event["s3"]["object"]["key"]

        print(f"Processing object: s3://{bucket}/{object_key}")
        

        workflow_table.put_item(
        Item={
            "s3_prefix": object_key,
            "s3_bucket":bucket,
            "upload_time": datetime.utcnow().isoformat(),
            "workflow_status": "TODO"
        }
    )

    return {"status": "done"}
