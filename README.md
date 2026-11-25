# Automating Schema Evolution on Apache Iceberg Tables in the Lakehouse Runtime Catalog

Sample code for the article on adding, widening, renaming, and dropping columns on a shared Apache Iceberg table, read and written by Apache Spark (Managed Service for Apache Spark batches) and BigQuery through Google Cloud's Lakehouse runtime catalog and the Apache Iceberg REST catalog endpoint.

| Path | What it does |
|---|---|
| `config.env` | Project, region, and resource names |
| `scripts/00_setup_project.sh` | APIs, Private Google Access, roles, scripts bucket |
| `scripts/01_bucket_and_catalog.sh` | Bucket and multiple-bucket catalog in credential vending mode |
| `scripts/spark.sh` | Submits a PySpark script as a Managed Service for Apache Spark batch |
| `scripts/bq.sh` | Runs a BigQuery SQL file against the shared table |
| `spark/run_sql.py` | Runs a SQL file statement by statement, printing results and errors |
| `spark/merge_write.py` | Ingest batch with a new column, evolved on write |
| `spark/schema_gate.py` | Schema gate: auto-applies safe changes, blocks breaking ones |
| `sql/` | Spark and BigQuery SQL for each section |
| `RUNBOOK.md` | Run order |

Requirements: Managed Service for Apache Spark runtime 2.2. BigQuery DML and DDL on Apache Iceberg tables in the Lakehouse runtime catalog are in Preview.
