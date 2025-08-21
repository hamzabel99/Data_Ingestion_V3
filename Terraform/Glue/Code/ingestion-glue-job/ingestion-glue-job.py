import sys
import json
import os
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.sql.functions import col, to_timestamp

# Arguments passés par la Step Function
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'input_event'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Charger l'event JSON passé depuis la Step Function
event = json.loads(args['input_event'])
files_to_process = event.get("files_to_process", [])

output_bucket = os.environ.get("OUTPUT_BUCKET", "postworkflow-ingestion-bucket")

for f in files_to_process:
    s3_bucket = f['input_bucket']
    s3_key = f['s3_key']
    
    input_path = f"s3://{s3_bucket}/{s3_key}"
    
    # Lecture CSV (ignorer les fichiers non CSV)
    if not s3_key.lower().endswith(".csv"):
        print(f"Skipping non-CSV file: {s3_key}")
        continue
    
    df = spark.read.option("header", True).csv(input_path)
    
    # Transformation
    df_transformed = (
        df.withColumnRenamed("Open", "open_price")
          .withColumnRenamed("Close", "close_price")
          .withColumnRenamed("High", "high_price")
          .withColumnRenamed("Low", "low_price")
          .withColumnRenamed("Volume", "volume")
          .withColumn("timestamp", to_timestamp(col("Date"), "yyyy-MM-dd HH:mm:ss"))
          .withColumn("price_change", col("close_price").cast("double") - col("open_price").cast("double"))
          .drop("Date")
    )
    
    # Écriture Parquet séparée pour chaque fichier
    file_basename = os.path.splitext(os.path.basename(s3_key))[0]
    output_path = f"s3://{output_bucket}/{file_basename}/"
    
    df_transformed.write.mode("overwrite").parquet(output_path)
    print(f"Processed and wrote {s3_key} -> {output_path}")

job.commit()
