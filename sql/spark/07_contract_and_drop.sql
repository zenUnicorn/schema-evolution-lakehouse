-- CONTRACT: once readers use order_total, drop amount.
ALTER TABLE schema_evo_catalog.shop.orders DROP COLUMN amount;

-- Dropping: metadata-only, and the old values are not coming back.
SELECT order_id, discount_code FROM schema_evo_catalog.shop.orders WHERE discount_code IS NOT NULL;
SELECT COUNT(*) AS data_files FROM schema_evo_catalog.shop.orders.files;

ALTER TABLE schema_evo_catalog.shop.orders DROP COLUMN discount_code;
SELECT COUNT(*) AS data_files FROM schema_evo_catalog.shop.orders.files;

-- Re-adding the same name creates a NEW column with a new ID; order 1009 does not get SAVE10 back.
ALTER TABLE schema_evo_catalog.shop.orders ADD COLUMN discount_code STRING;
SELECT order_id, discount_code FROM schema_evo_catalog.shop.orders WHERE order_id = 1009;

-- Tidy up before the schema gate section.
ALTER TABLE schema_evo_catalog.shop.orders DROP COLUMN discount_code;
DESCRIBE schema_evo_catalog.shop.orders;
SELECT * FROM schema_evo_catalog.shop.orders ORDER BY order_id;
