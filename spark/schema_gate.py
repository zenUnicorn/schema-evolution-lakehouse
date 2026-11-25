"""A schema gate for an ingest job writing to an Apache Iceberg table.

Compares each incoming batch with the table's current schema:
  auto-apply : new columns, and legal type widenings (int->bigint, float->double,
               decimal precision increase at the same scale)
  block      : missing columns, narrowing or incompatible types, and probable renames
               (a column disappears and a new one of the same type appears)
A blocked batch writes nothing. A clean batch has its changes applied, then is appended.
"""
from datetime import datetime
from decimal import Decimal
from pyspark.sql import SparkSession
from pyspark.sql.functions import col
from pyspark.sql.types import (StructType, StructField, LongType, IntegerType, FloatType,
                               DoubleType, StringType, DecimalType, TimestampType, BooleanType)

spark = SparkSession.builder.appName("schema_gate").getOrCreate()
spark.sparkContext.setLogLevel("ERROR")
TABLE = "schema_evo_catalog.shop.orders"


def is_widening(old, new):
    """True if Iceberg can promote `old` to `new` as a metadata-only change."""
    if isinstance(old, IntegerType) and isinstance(new, LongType):
        return True
    if isinstance(old, FloatType) and isinstance(new, DoubleType):
        return True
    if isinstance(old, DecimalType) and isinstance(new, DecimalType):
        return new.scale == old.scale and new.precision > old.precision
    return False


def plan(table_schema, batch_schema):
    table = {f.name: f.dataType for f in table_schema.fields}
    batch = {f.name: f.dataType for f in batch_schema.fields}
    missing = [c for c in table if c not in batch]
    new = [c for c in batch if c not in table]
    apply, block = [], []

    # A column that vanished plus a new column of the same type looks like a rename.
    for m in list(missing):
        twin = next((n for n in new if batch[n] == table[m]), None)
        if twin:
            block.append(f"probable rename: {m} -> {twin} ({table[m].simpleString()})")
            missing.remove(m)
            new.remove(twin)

    block += [f"missing column: {m}" for m in missing]
    apply += [("add", n, batch[n]) for n in new]

    for c in table:
        if c in batch and batch[c] != table[c]:
            if is_widening(table[c], batch[c]):
                apply.append(("widen", c, batch[c]))
            elif is_widening(batch[c], table[c]):
                block.append(f"narrowing: {c} {table[c].simpleString()} -> {batch[c].simpleString()}")
            else:
                block.append(f"incompatible type: {c} {table[c].simpleString()} -> {batch[c].simpleString()}")
    return apply, block


def gate(name, df):
    print(f"\n=== {name}", flush=True)
    apply, block = plan(spark.table(TABLE).schema, df.schema)
    for kind, c, t in apply:
        print(f"  {'+ add  ' if kind == 'add' else '^ widen'} {c} {t.simpleString()}")
    for reason in block:
        print(f"  x {reason}")

    if block:
        print("  DECISION: BLOCKED, nothing written. Needs human review.")
        return

    for kind, c, t in apply:
        if kind == "add":
            spark.sql(f"ALTER TABLE {TABLE} ADD COLUMN {c} {t.simpleString()}")
        else:
            spark.sql(f"ALTER TABLE {TABLE} ALTER COLUMN {c} TYPE {t.simpleString()}")

    target = spark.table(TABLE).schema
    aligned = df.select([col(f.name).cast(f.dataType) for f in target.fields if f.name in df.columns])
    aligned.writeTo(TABLE).append()
    print(f"  DECISION: APPLIED {len(apply)} change(s), wrote {df.count()} row(s).")


ts = datetime(2026, 11, 6, 9, 0)

# Batch 1: safe. order_total arrives as DECIMAL(12,2) (widen) and gift_wrap is new (add).
b1 = spark.createDataFrame(
    [(2001, 5000000001, "pending", 2, ts, "web", Decimal("18.00"), True),
     (2002, 5000000002, "paid", 1, ts, "app", Decimal("64.00"), False)],
    StructType([StructField("order_id", LongType()), StructField("customer_id", LongType()),
                StructField("status", StringType()), StructField("quantity", LongType()),
                StructField("updated_at", TimestampType()), StructField("channel", StringType()),
                StructField("order_total", DecimalType(12, 2)), StructField("gift_wrap", BooleanType())]))

# Batch 2: breaking. channel is missing and quantity arrives as INT (narrowing).
b2 = spark.createDataFrame(
    [(2003, 509, "pending", 3, ts, Decimal("30.00"), False)],
    StructType([StructField("order_id", LongType()), StructField("customer_id", LongType()),
                StructField("status", StringType()), StructField("quantity", IntegerType()),
                StructField("updated_at", TimestampType()), StructField("order_total", DecimalType(12, 2)),
                StructField("gift_wrap", BooleanType())]))

# Batch 3: breaking. The producer renamed status to order_status.
b3 = spark.createDataFrame(
    [(2004, 510, "paid", 1, ts, "store", Decimal("12.00"), False)],
    StructType([StructField("order_id", LongType()), StructField("customer_id", LongType()),
                StructField("order_status", StringType()), StructField("quantity", LongType()),
                StructField("updated_at", TimestampType()), StructField("channel", StringType()),
                StructField("order_total", DecimalType(12, 2)), StructField("gift_wrap", BooleanType())]))

print("\n>>> Table schema before the gate:")
print(", ".join(f"{f.name} {f.dataType.simpleString()}" for f in spark.table(TABLE).schema.fields))

gate("Batch 1: new column + widened decimal", b1)
gate("Batch 2: missing column + narrowed type", b2)
gate("Batch 3: renamed column", b3)

print("\n>>> Table schema after the gate:")
print(", ".join(f"{f.name} {f.dataType.simpleString()}" for f in spark.table(TABLE).schema.fields))
spark.sql(f"SELECT order_id, customer_id, status, channel, gift_wrap FROM {TABLE} "
          f"WHERE order_id >= 2000 ORDER BY order_id").show(truncate=False)
