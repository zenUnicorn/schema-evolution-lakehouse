#!/usr/bin/env bash
# Run one BigQuery SQL file against the shared table and keep the output (errors included).
#   ./scripts/bq.sh <capture-name> sql/bigquery/<file>.sql
set -uo pipefail
source "$(dirname "$0")/../config.env"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAME="$1"; FILE="$2"
QUERY="$(grep -v '^--' "${ROOT}/${FILE}" | envsubst)"
{
  echo "\$ ${QUERY}"
  bq query --project_id="${PROJECT_ID}" --location="${REGION}" \
    --use_legacy_sql=false --format=pretty "${QUERY}"
  echo "(exit code: $?)"
} 2>&1 | tee "${ROOT}/captures/${NAME}.txt"
