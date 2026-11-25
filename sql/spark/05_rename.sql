-- Renaming: the table survives. Old files are still read through the column ID.
ALTER TABLE schema_evo_catalog.shop.orders RENAME COLUMN amount TO order_total;
DESCRIBE schema_evo_catalog.shop.orders;
SELECT order_id, order_total FROM schema_evo_catalog.shop.orders ORDER BY order_id;
