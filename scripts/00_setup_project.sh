#!/usr/bin/env bash
# Enable APIs, turn on Private Google Access for batches, grant roles, create the scripts bucket.
set -euo pipefail
source "$(dirname "$0")/../config.env"

gcloud config set project "${PROJECT_ID}"

gcloud services enable \
  biglake.googleapis.com dataproc.googleapis.com storage.googleapis.com \
  bigquery.googleapis.com compute.googleapis.com

# Managed Service for Apache Spark batches run on the region's subnet and need Private Google Access.
gcloud compute networks subnets update default \
  --region="${REGION}" --enable-private-ip-google-access

PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}" --format='value(projectNumber)')
SPARK_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
echo "Spark service account: ${SPARK_SA}"

for ROLE in roles/dataproc.worker roles/serviceusage.serviceUsageConsumer \
            roles/biglake.editor roles/bigquery.dataEditor; do
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SPARK_SA}" --role="${ROLE}" --condition=None --quiet > /dev/null
  echo "Granted ${ROLE}"
done

# Bucket for scripts and SQL files (not the table's bucket).
gcloud storage buckets create "gs://${DEPS_BUCKET}" \
  --location="${REGION}" --uniform-bucket-level-access
gcloud storage buckets add-iam-policy-binding "gs://${DEPS_BUCKET}" \
  --member="serviceAccount:${SPARK_SA}" --role="roles/storage.objectUser" > /dev/null
echo "Scripts bucket ready: gs://${DEPS_BUCKET}"
