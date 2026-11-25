-- BigQuery reads the new Spark-added column: NULL for rows written before it existed.
SELECT order_id, status, channel FROM `${BQ_TABLE}` ORDER BY order_id
