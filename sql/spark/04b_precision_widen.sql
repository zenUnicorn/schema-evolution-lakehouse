-- Which decimal widenings does the catalog accept? BigQuery NUMERIC = precision 38, scale 9
-- (at most 29 digits before the decimal point).
ALTER TABLE schema_evo_catalog.shop.precision_probe ALTER COLUMN price TYPE DECIMAL(33,4);
DESCRIBE schema_evo_catalog.shop.precision_probe;
ALTER TABLE schema_evo_catalog.shop.precision_probe ALTER COLUMN price TYPE DECIMAL(38,4);
DESCRIBE schema_evo_catalog.shop.precision_probe;
