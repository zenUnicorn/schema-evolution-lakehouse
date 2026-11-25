#!/usr/bin/env bash
# Submit a PySpark script as a Managed Service for Apache Spark batch.
#   ./scripts/spark.sh <capture-name> <script.py> [script args...]
# Example:
#   ./scripts/spark.sh 02_create_table spark/run_sql.py sql/spark/01_create_table.sql
# Any argument that is a local sql/ file path is passed as its gs:// copy.
set -uo pipefail
source "$(dirname "$0")/../config.env"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAME="$1"; SCRIPT="$2"; shift 2

# Keep the SQL files in the scripts bucket current.
gcloud storage cp -r "${ROOT}/sql" "gs://${DEPS_BUCKET}/" --quiet > /dev/null

ARGS=()
for a in "$@"; do
  if [[ "$a" == sql/* ]]; then ARGS+=("gs://${DEPS_BUCKET}/$a"); else ARGS+=("$a"); fi
done

C="spark.sql.catalog.${CATALOG_ID}"
PROPS="^#^spark.sql.defaultCatalog=${CATALOG_ID}"
PROPS+="#${C}=org.apache.iceberg.spark.SparkCatalog"
PROPS+="#${C}.type=rest"
PROPS+="#${C}.uri=https://biglake.googleapis.com/iceberg/v1/restcatalog"
PROPS+="#${C}.warehouse=${WAREHOUSE}"
PROPS+="#${C}.io-impl=org.apache.iceberg.gcp.gcs.GCSFileIO"
PROPS+="#${C}.header.x-goog-user-project=${PROJECT_ID}"
PROPS+="#${C}.rest.auth.type=org.apache.iceberg.gcp.auth.GoogleAuthManager"
PROPS+="#${C}.header.X-Iceberg-Access-Delegation=vended-credentials"
PROPS+="#${C}.gcs.oauth2.refresh-credentials-endpoint=https://oauth2.googleapis.com/token"
PROPS+="#spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions"

gcloud dataproc batches submit pyspark "${ROOT}/${SCRIPT}" \
  --project="${PROJECT_ID}" \
  --region="${REGION}" \
  --version="${SPARK_RUNTIME}" \
  --deps-bucket="gs://${DEPS_BUCKET}" \
  --properties="${PROPS}" \
  -- "${ARGS[@]}" 2>&1 \
  | grep -vE "^(Using the default container image|Waiting for container log creation|PYSPARK_PYTHON=|JAVA_HOME=|SPARK_EXTRA_CLASSPATH=|:: loading settings|Ivy Default)" \
  | tee "${ROOT}/captures/${NAME}.txt"
