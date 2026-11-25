-- Adding Columns: Spark sees the column BigQuery added, and writes to it.
DESCRIBE schema_evo_catalog.shop.orders;

INSERT INTO schema_evo_catalog.shop.orders
SELECT * FROM VALUES
  (1009, 507, 'pending', 15.50, 1, TIMESTAMP '2026-11-04 10:05:00', 'web', 'SAVE10')
AS v(order_id, customer_id, status, amount, quantity, updated_at, channel, discount_code);

SELECT order_id, status, channel, discount_code
FROM schema_evo_catalog.shop.orders ORDER BY order_id;
