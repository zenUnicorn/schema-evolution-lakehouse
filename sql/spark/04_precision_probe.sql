-- Widening a Column Type: decimal precision versus BigQuery NUMERIC (precision 38, scale 9).
-- Separate scratch tables, so the orders table is never at risk.
CREATE TABLE schema_evo_catalog.shop.precision_probe (id INT, price DECIMAL(18,4))
USING iceberg TBLPROPERTIES ('format-version' = '2');
INSERT INTO schema_evo_catalog.shop.precision_probe VALUES (1, 12345.6789);

ALTER TABLE schema_evo_catalog.shop.precision_probe ALTER COLUMN price TYPE DECIMAL(38,4);
INSERT INTO schema_evo_catalog.shop.precision_probe
VALUES (2, 1234567890123456789012345678901234.5678);
SELECT * FROM schema_evo_catalog.shop.precision_probe ORDER BY id;

CREATE TABLE schema_evo_catalog.shop.precision_probe_scale (id INT, rate DECIMAL(38,12))
USING iceberg TBLPROPERTIES ('format-version' = '2');
INSERT INTO schema_evo_catalog.shop.precision_probe_scale VALUES (1, 0.123456789012);
SELECT * FROM schema_evo_catalog.shop.precision_probe_scale;
