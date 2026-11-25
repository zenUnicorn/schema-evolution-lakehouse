-- Backfill from BigQuery DML: copy amount into order_total for every row that lacks it.
UPDATE `${BQ_TABLE}` SET order_total = amount WHERE order_total IS NULL
