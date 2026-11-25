# Runbook: Automating Schema Evolution (Article 2)

Everything runs in **Cloud Shell**. No cluster, no SSH.
Each Spark step is a Managed Service for Apache Spark batch and takes about 1 to 3 minutes to start and finish.
Every step saves its output to `captures/`.

## 0. Load the repo and set your project

Upload `schema-evolution-lakehouse.zip` (three-dot menu > Upload), then:

```bash
cd ~ && unzip -o schema-evolution-lakehouse.zip && cd schema-evolution-lakehouse
sed -i 's/your-project-id/YOUR_NEW_PROJECT_ID/' config.env
source config.env && chmod +x scripts/*.sh
gcloud config set project $PROJECT_ID
echo $PROJECT_ID $CATALOG_ID
```

## 1. Project setup (APIs, network, roles, scripts bucket)

```bash
./scripts/00_setup_project.sh
```

## 2. Bucket and catalog  →  article: Creating the Catalog and the Orders Table

```bash
./scripts/01_bucket_and_catalog.sh
```

## 3. Create the table from Spark

```bash
./scripts/spark.sh 02_create_table spark/run_sql.py sql/spark/01_create_table.sql
```

## 4. Adding columns  →  article: Adding Columns Automatically with Schema Merge

```bash
./scripts/spark.sh 03_merge_write spark/merge_write.py
./scripts/bq.sh 04_bq_read_channel sql/bigquery/01_read_channel.sql
./scripts/bq.sh 05_bq_add_discount_code sql/bigquery/02_add_discount_code.sql
./scripts/spark.sh 06_spark_after_bq_add spark/run_sql.py sql/spark/02_after_bq_add_column.sql
./scripts/bq.sh 07_bq_read_discount_code sql/bigquery/03_read_discount_code.sql
```

## 5. Widening  →  article: Widening a Column Type

```bash
./scripts/spark.sh 08_widen spark/run_sql.py sql/spark/03_widen.sql
./scripts/bq.sh 09_bq_read_quantity sql/bigquery/04_read_quantity.sql
./scripts/spark.sh 10_precision_probe spark/run_sql.py sql/spark/04_precision_probe.sql
./scripts/bq.sh 11a_bq_precision sql/bigquery/05a_precision_probe.sql
./scripts/bq.sh 11b_bq_precision_scale sql/bigquery/05b_precision_probe_scale.sql
```

## 6. Rename  →  article: Renaming and Dropping

```bash
gcloud biglake iceberg tables describe orders --project=$PROJECT_ID --catalog=$CATALOG_ID --namespace=shop > captures/12a_schema_before_rename.txt
./scripts/spark.sh 12_rename spark/run_sql.py sql/spark/05_rename.sql
gcloud biglake iceberg tables describe orders --project=$PROJECT_ID --catalog=$CATALOG_ID --namespace=shop > captures/12b_schema_after_rename.txt
./scripts/bq.sh 13_bq_old_name sql/bigquery/06_old_name.sql
./scripts/bq.sh 14_bq_new_name sql/bigquery/07_new_name.sql
```

📸 **Screenshot A (do it now, before step 7):** BigQuery Studio, run
`SELECT order_id, amount FROM \`YOUR_PROJECT.schema_evo_catalog.shop.orders\`` and screenshot the error.

## 7. Expand and contract, then drop

```bash
./scripts/spark.sh 15_expand spark/run_sql.py sql/spark/06_expand.sql
./scripts/bq.sh 16a_bq_backfill sql/bigquery/08a_backfill.sql
./scripts/bq.sh 16_bq_both_names sql/bigquery/08_both_names.sql
./scripts/spark.sh 17_contract_and_drop spark/run_sql.py sql/spark/07_contract_and_drop.sql
./scripts/bq.sh 18_bq_read_all sql/bigquery/09_read_all.sql
```

## 8. Schema gate  →  article: A Schema Gate for the Ingest Job

```bash
./scripts/spark.sh 19_schema_gate spark/schema_gate.py
./scripts/bq.sh 20_bq_after_gate sql/bigquery/09_read_all.sql
```

📸 **Screenshot B:** Console > Lakehouse > schema_evo_catalog > shop > orders, the Schema tab showing the final columns.

## 9. Send results, then clean up

```bash
zip -r captures.zip captures
./scripts/99_cleanup.sh      # only after the article is approved
```
