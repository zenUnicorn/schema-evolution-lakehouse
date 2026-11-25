"""An ingest batch arrives with a column the table doesn't have yet (channel).

With write.spark.accept-any-schema=true on the table and mergeSchema on the write,
Iceberg adds the column as part of the same commit as the data.
"""
from datetime import datetime
from decimal import Decimal
from pyspark.sql import SparkSession
from pyspark.sql.types import (StructType, StructField, LongType, IntegerType,
                               StringType, DecimalType, TimestampType)

spark = SparkSession.builder.appName("merge_write").getOrCreate()
spark.sparkContext.setLogLevel("ERROR")
TABLE = "shop.orders"

schema = StructType([
    StructField("order_id", LongType()),
    StructField("customer_id", IntegerType()),
    StructField("status", StringType()),
    StructField("amount", DecimalType(10, 2)),
    StructField("quantity", IntegerType()),
    StructField("updated_at", TimestampType()),
    StructField("channel", StringType()),          # new column
])
rows = [
    (1006, 505, "pending", Decimal("42.00"), 1, datetime(2026, 11, 3, 9, 0), "web"),
    (1007, 502, "paid", Decimal("310.75"), 4, datetime(2026, 11, 3, 9, 12), "app"),
    (1008, 506, "pending", Decimal("64.10"), 2, datetime(2026, 11, 3, 9, 40), "store"),
]
batch = spark.createDataFrame(rows, schema)

print("\n>>> Table columns before the write:")
print([f.name for f in spark.table(TABLE).schema.fields])

batch.writeTo(TABLE).option("mergeSchema", "true").append()

print("\n>>> Table columns after the write:")
print([f.name for f in spark.table(TABLE).schema.fields])
print("\n>>> Rows:")
spark.sql(f"SELECT order_id, status, quantity, channel FROM {TABLE} ORDER BY order_id").show(truncate=False)
