#!/usr/bin/env bash
# Deletes everything this tutorial created.
set -uo pipefail
source "$(dirname "$0")/../config.env"
for T in orders widen_demo precision_probe precision_probe_scale; do
  gcloud biglake iceberg tables delete "${T}" --project="${PROJECT_ID}" \
    --catalog="${CATALOG_ID}" --namespace="${NAMESPACE}" --quiet
done
gcloud biglake iceberg namespaces delete "${NAMESPACE}" --project="${PROJECT_ID}" --catalog="${CATALOG_ID}" --quiet
gcloud biglake iceberg catalogs delete "${CATALOG_ID}" --project="${PROJECT_ID}" --quiet
gcloud storage rm -r "gs://${BUCKET_NAME}" "gs://${DEPS_BUCKET}"
