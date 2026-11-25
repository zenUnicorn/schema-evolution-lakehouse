-- Creating the Catalog and the Orders Table: Spark sets every property from the first commit.
CREATE NAMESPACE IF NOT EXISTS schema_evo_catalog.shop;

CREATE TABLE IF NOT EXISTS schema_evo_catalog.shop.orders (
  order_id     BIGINT,
  customer_id  INT,
  status       STRING,
  amount       DECIMAL(10,2),
  quantity     INT,
  updated_at   TIMESTAMP
)
USING iceberg
TBLPROPERTIES (
  'format-version'                       = '2',
  'gcp.biglake.bigquery-dml.enabled'     = 'true',
  'gcp.biglake.table-management.enabled' = 'true',
  'write.delete.mode'                    = 'copy-on-write',
  'write.update.mode'                    = 'copy-on-write',
  'write.merge.mode'                     = 'copy-on-write',
  'write.spark.accept-any-schema'        = 'true'
);

-- accept-any-schema makes Spark match columns by name, so the values get names.
INSERT INTO schema_evo_catalog.shop.orders
SELECT * FROM VALUES
  (1001, 501, 'pending', 49.99,  2, TIMESTAMP '2026-11-01 09:15:00'),
  (1002, 502, 'paid',    120.00, 1, TIMESTAMP '2026-11-01 10:42:00'),
  (1003, 501, 'shipped', 18.50,  3, TIMESTAMP '2026-11-01 11:05:00'),
  (1004, 503, 'pending', 75.25,  1, TIMESTAMP '2026-11-02 08:30:00'),
  (1005, 504, 'paid',    260.00, 6, TIMESTAMP '2026-11-02 13:20:00')
AS v(order_id, customer_id, status, amount, quantity, updated_at);

SHOW TBLPROPERTIES schema_evo_catalog.shop.orders;
DESCRIBE schema_evo_catalog.shop.orders;
SELECT * FROM schema_evo_catalog.shop.orders ORDER BY order_id;
