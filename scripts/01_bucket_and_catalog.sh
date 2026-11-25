#!/usr/bin/env bash
# Table bucket + multiple-bucket catalog in credential vending mode (same pattern as Article 1).
set -euo pipefail
source "$(dirname "$0")/../config.env"

gcloud storage buckets create "gs://${BUCKET_NAME}" \
  --location="${REGION}" --uniform-bucket-level-access

gcloud biglake iceberg catalogs create "${CATALOG_ID}" \
  --project="${PROJECT_ID}" \
  --catalog-type=biglake \
  --default-location="gs://${BUCKET_NAME}" \
  --credential-mode=vended-credentials

CATALOG_SA=$(gcloud biglake iceberg catalogs describe "${CATALOG_ID}" \
  --project="${PROJECT_ID}" --format='value(biglake-service-account)')
echo "Catalog service account: ${CATALOG_SA}"

for i in 1 2 3 4 5; do
  if gcloud storage buckets add-iam-policy-binding "gs://${BUCKET_NAME}" \
      --member="serviceAccount:${CATALOG_SA}" --role="roles/storage.objectUser" > /dev/null; then
    echo "Granted roles/storage.objectUser to the catalog service account"; break
  fi
  echo "Grant failed (attempt ${i}), waiting 20s..."; sleep 20
done

gcloud biglake iceberg catalogs describe "${CATALOG_ID}" --project="${PROJECT_ID}" \
  | tee "$(dirname "$0")/../captures/01_catalog_describe.txt"
