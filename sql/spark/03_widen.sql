-- Widening a Column Type: INT to BIGINT is metadata-only.
-- Shown on a small Spark-only table, because BigQuery's ADD COLUMN on the orders table
-- had already promoted orders.quantity and orders.customer_id from INT to BIGINT.
CREATE TABLE IF NOT EXISTS schema_evo_catalog.shop.widen_demo (id BIGINT, qty INT)
USING iceberg TBLPROPERTIES ('format-version' = '2');
INSERT INTO schema_evo_catalog.shop.widen_demo VALUES (1, 2), (2, 7);

SELECT COUNT(*) AS data_files FROM schema_evo_catalog.shop.widen_demo.files;
SELECT COUNT(*) AS metadata_files FROM schema_evo_catalog.shop.widen_demo.metadata_log_entries;

ALTER TABLE schema_evo_catalog.shop.widen_demo ALTER COLUMN qty TYPE BIGINT;

DESCRIBE schema_evo_catalog.shop.widen_demo;
SELECT COUNT(*) AS data_files FROM schema_evo_catalog.shop.widen_demo.files;
SELECT COUNT(*) AS metadata_files FROM schema_evo_catalog.shop.widen_demo.metadata_log_entries;

-- A value that would not fit in INT
INSERT INTO schema_evo_catalog.shop.widen_demo VALUES (3, 5000000000);
SELECT * FROM schema_evo_catalog.shop.widen_demo ORDER BY id;

-- Narrowing back is not a legal promotion: this is expected to fail.
ALTER TABLE schema_evo_catalog.shop.widen_demo ALTER COLUMN qty TYPE INT;
