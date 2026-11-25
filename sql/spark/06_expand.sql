-- Expand and contract. First undo the hard rename, then EXPAND:
-- add the new column, backfill it, and dual-write both for a while.
ALTER TABLE schema_evo_catalog.shop.orders RENAME COLUMN order_total TO amount;

ALTER TABLE schema_evo_catalog.shop.orders ADD COLUMN order_total DECIMAL(10,2);

-- The backfill (order_total = amount) runs from BigQuery DML in the next step.

-- New writes fill both columns until every reader has moved over.
INSERT INTO schema_evo_catalog.shop.orders
SELECT * FROM VALUES
  (1011, 508, 'pending', 27.40, 1, TIMESTAMP '2026-11-05 08:00:00', 'app', CAST(NULL AS STRING), 27.40)
AS v(order_id, customer_id, status, amount, quantity, updated_at, channel, discount_code, order_total);

SELECT order_id, amount, order_total FROM schema_evo_catalog.shop.orders ORDER BY order_id;
