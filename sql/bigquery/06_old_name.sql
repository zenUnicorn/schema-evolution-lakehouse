-- A downstream query written against the old name. Expected to fail after the rename.
SELECT order_id, amount FROM `${BQ_TABLE}` ORDER BY order_id
