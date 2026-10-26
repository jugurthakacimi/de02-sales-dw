from pathlib import Path
import duckdb


# Paths
DB_PATH = Path("warehouse/amazon.duckdb")
BRONZE_SQL = Path("sql/bronze.sql")
SILVER_SQL = Path("sql/silver.sql")
GOLD_SQL = Path("sql/gold.sql")

# connect to DuckDB
con = duckdb.connect(
    DB_PATH, read_only=False, config={"storage_compatibility_version": "v1.5.6"}
)

# Bronze Layer
sql = BRONZE_SQL.read_text(encoding="utf-8")
con.execute(sql)
print("Bronze Layer Successful")


# Silver Layer
sql = SILVER_SQL.read_text(encoding="utf-8")
for statement in con.extract_statements(sql):
    con.execute(statement.query)
print("Silver Layer Successful")


# Gold layer
sql = GOLD_SQL.read_text(encoding="utf-8")
for statement in con.extract_statements(sql):
    con.execute(statement.query)
print("Gold Layer Successful")

con.close()
