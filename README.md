## Part 3 – Alert and Monitoring for stuck files

**Note:** Make sure to check out the [Version 1 repository](https://github.com/hamzabel99/Data_Ingestion_V1) and the [Version 2 repository](https://github.com/hamzabel99/Data_Ingestion_V2) first, as it’s essential to understand the foundation before diving into Version 2.

![Pipeline Architecture](Architecture_ingestion_V3.png)

For the 3rd version, I added a monitoring tool that tracks any files stuck in the workflow for an extended period. At the end of each day, a Lambda scans the Workflow_status table, identifies files still in "TODO" status past a configurable threshold (e.g., 48 hours), and sends an alert email via SNS. This allows timely alerts for potential bottlenecks without manually checking the pipeline.

![Email Alert](Email%20Alert.png)


