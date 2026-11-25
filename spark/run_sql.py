"""Run every statement in a SQL file (read from Cloud Storage) and print each result.

A failing statement is printed with its error and the run continues, so expected
failures (like a narrowing ALTER) show up in the output instead of ending the batch.
"""
import sys
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("run_sql").getOrCreate()
spark.sparkContext.setLogLevel("ERROR")

path = sys.argv[1]
text = spark.read.text(path, wholetext=True).collect()[0][0]
lines = [l for l in text.splitlines() if not l.strip().startswith("--")]
statements = [s.strip() for s in "\n".join(lines).split(";") if s.strip()]

for stmt in statements:
    print("\n>>> " + " ".join(stmt.split()), flush=True)
    try:
        df = spark.sql(stmt)
        if df.columns:
            df.show(100, truncate=False)
        else:
            print("OK")
    except Exception as e:  # keep going so expected failures are captured
        msg = [l.strip() for l in str(e).splitlines() if l.strip()]
        useful = [l for l in msg if ("Exception" in l or "Error" in l or "error" in l)
                  and not l.startswith("at ")][:4] or msg[:1]
        for l in useful:
            print("ERROR: " + l[:500])
