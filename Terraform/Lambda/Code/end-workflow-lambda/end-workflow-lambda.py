import boto3
import json
from datetime import datetime
import os

# Initialisation DynamoDB
dynamodb = boto3.resource("dynamodb")
table_name = os.environ.get("WORKFLOW_TABLE", "workflow_statut")
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    """
    Event attendu depuis Step Function :
    {
      "input_bucket": "...",
      "s3_key": "...",
      "--input_event": {
        "files_to_process": [...]
      }
    }
    """
    
    print(f"📥 Event reçu: {json.dumps(event, indent=2)}")
    
    # Récupérer les fichiers à traiter
    files_to_process = []
    
    # Cas 1: --input_event contient l'objet complet
    if "--input_event" in event:
        input_event = event["--input_event"]
        
        # Si c'est un string JSON, le décoder
        if isinstance(input_event, str):
            input_event = json.loads(input_event)
        
        # Extraire files_to_process
        if isinstance(input_event, dict):
            files_to_process = input_event.get("files_to_process", [])
        elif isinstance(input_event, list):
            # Si c'est directement un array de fichiers
            files_to_process = input_event
    
    # Cas 2: Fallback - chercher files_to_process à la racine
    elif "files_to_process" in event:
        files_to_process = event["files_to_process"]
    
    else:
        raise ValueError("Impossible de trouver les fichiers à traiter dans l'event")
    
    if not files_to_process:
        print("⚠️ Aucun fichier trouvé dans files_to_process")
        return {"updated": 0}

    print(f"📁 {len(files_to_process)} fichiers à marquer comme DONE")
    
    updated_count = 0
    for f in files_to_process:
        s3_key = f["s3_key"]

        try:
            # Mettre à jour DynamoDB pour chaque fichier
            table.update_item(
                Key={"s3_prefix": s3_key},
                UpdateExpression="SET end_time = :et, #st = :st",
                ExpressionAttributeValues={
                    ":et": datetime.utcnow().isoformat(),
                    ":st": "DONE",
                },
                ExpressionAttributeNames={
                    "#st": "status"  # status est un mot réservé
                },
            )
            updated_count += 1
            print(f"✅ Fichier {s3_key} marqué DONE")
            
        except Exception as e:
            print(f"❌ Erreur lors de la mise à jour de {s3_key}: {e}")
            raise

    print(f"🎉 Workflow terminé - {updated_count} fichiers mis à jour")
    return {
        "updated": updated_count,
        "files_processed": [f["s3_key"] for f in files_to_process]
    }