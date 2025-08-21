import boto3
import os
from datetime import datetime, timedelta
from boto3.dynamodb.conditions import Attr


# Configuration
WORKFLOW_TABLE = os.environ.get("WORKFLOW_TABLE", "workflow_statut")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")

# Initialisation clients AWS
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(WORKFLOW_TABLE)
sns = boto3.client('sns')

# Définir le délai au-delà duquel un fichier est considéré "stuck"
STALE_HOURS = int(os.environ.get("STALE_HOURS", 5))

def lambda_handler(event, context):
    now = datetime.utcnow()
    cutoff_time = now - timedelta(hours=STALE_HOURS)

    # Scan complet de la table (si table très grande, utiliser un index ou query + pagination)
    response = table.scan(
    FilterExpression=Attr("workflow_status").eq("TODO")  # ou ton nom de colonne définitif
)

    items = response.get('Items', [])

    # Filtrer les fichiers "stuck"
    stuck_files = []
    for item in items:
        upload_time_str = item.get("upload_time")
        if not upload_time_str:
            continue
        upload_time = datetime.fromisoformat(upload_time_str)
        if upload_time < cutoff_time:
            stuck_files.append({
                "s3_prefix": item.get("s3_prefix"),
                "s3_bucket": item.get("s3_bucket"),
                "upload_time": upload_time_str
            })

    if not stuck_files:
        print("No stuck files found.")
        return {"stuck_files_count": 0}

    # Construire le message
    message = f"Found {len(stuck_files)} stuck files in DynamoDB:\n\n"
    for f in stuck_files:
        message += f"- {f['s3_bucket']}/{f['s3_prefix']} uploaded at {f['upload_time']}\n"

    # Publier sur SNS
    response = sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject=f"[ALERT] {len(stuck_files)} Stuck Workflow Files",
        Message=message
    )
    print(f"Published SNS message: {response.get('MessageId')}")

    return {"stuck_files_count": len(stuck_files)}
