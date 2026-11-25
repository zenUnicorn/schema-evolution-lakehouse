-- During expand: old and new readers both work.
SELECT order_id, amount, order_total FROM `${BQ_TABLE}` ORDER BY order_id
