#!/usr/bin/env bash
# Rebuilds the orders table and runs every orders step in order, end to end.
# Outputs land in captures/run2/. Takes about 30 minutes; keep the Cloud Shell tab open.
set -uo pipefail
cd "$(dirname "$0")/.."
source config.env
mkdir -p captures/run2
step () { echo; echo "################ $1 ################"; }

step "Reset: delete the orders table"
gcloud biglake iceberg tables delete orders --project="$PROJECT_ID" \
  --catalog="$CATALOG_ID" --namespace="$NAMESPACE" --quiet

step "Create and load";            ./scripts/spark.sh run2/02_create_table spark/run_sql.py sql/spark/01_create_table.sql
step "Schema merge on write";      ./scripts/spark.sh run2/03_merge_write spark/merge_write.py
step "BigQuery reads channel";     ./scripts/bq.sh run2/04_bq_read_channel sql/bigquery/01_read_channel.sql
step "BigQuery ADD COLUMN";        ./scripts/bq.sh run2/05_bq_add_discount_code sql/bigquery/02_add_discount_code.sql
step "Spark after BigQuery add";   ./scripts/spark.sh run2/06_spark_after_bq_add spark/run_sql.py sql/spark/02_after_bq_add_column.sql
step "BigQuery reads discount";    ./scripts/bq.sh run2/07_bq_read_discount_code sql/bigquery/03_read_discount_code.sql

step "Schema history"
LATEST=$(gcloud storage ls "gs://$BUCKET_NAME/shop/orders/**.metadata.json" | sort | tail -1)
gcloud storage cat "$LATEST" | python3 -c "import json,sys; m=json.load(sys.stdin); [print('schema', s['schema-id'], [(f['id'], f['name'], f['type']) for f in s['fields']]) for s in m['schemas']]" \
  | tee captures/run2/07b_schema_history.txt

step "Rename"
gcloud biglake iceberg tables describe orders --project="$PROJECT_ID" --catalog="$CATALOG_ID" --namespace="$NAMESPACE" \
  | grep -v "oauth2.token" > captures/run2/12a_schema_before_rename.txt
./scripts/spark.sh run2/12_rename spark/run_sql.py sql/spark/05_rename.sql
gcloud biglake iceberg tables describe orders --project="$PROJECT_ID" --catalog="$CATALOG_ID" --namespace="$NAMESPACE" \
  | grep -v "oauth2.token" > captures/run2/12b_schema_after_rename.txt
./scripts/bq.sh run2/13_bq_old_name sql/bigquery/06_old_name.sql
./scripts/bq.sh run2/14_bq_new_name sql/bigquery/07_new_name.sql

step "Expand";                      ./scripts/spark.sh run2/15_expand spark/run_sql.py sql/spark/06_expand.sql
step "Backfill from BigQuery";      ./scripts/bq.sh run2/16a_bq_backfill sql/bigquery/08a_backfill.sql
step "Both names readable";         ./scripts/bq.sh run2/16_bq_both_names sql/bigquery/08_both_names.sql
step "Contract and drop";           ./scripts/spark.sh run2/17_contract_and_drop spark/run_sql.py sql/spark/07_contract_and_drop.sql
step "BigQuery reads final table";  ./scripts/bq.sh run2/18_bq_read_all sql/bigquery/09_read_all.sql
step "Schema gate";                 ./scripts/spark.sh run2/19_schema_gate spark/schema_gate.py
step "BigQuery after the gate";     ./scripts/bq.sh run2/20_bq_after_gate sql/bigquery/09_read_all.sql

step "Packing outputs"
( cd captures && zip -qr run2.zip run2 ) && echo "Done. Download captures/run2.zip"
