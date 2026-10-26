from datetime import datetime
from pathlib import Path
import duckdb


# Paths
SOURCE_FILE = Path("data/raw/amazon.csv")
BRONZE_FILE = Path("data/bronze/amazon_bronze.parquet")
SILVER_FILE = Path("data/silver/amazon_silver.parquet")
db_path = Path("warehouse/amazon.duckdb")

# connect to DuckDB
con = duckdb.connect(db_path, read_only=False)


# Create the bronze snapshot to Parquet
con.execute(
    """
COPY (SELECT * exclude (discounted_price, actual_price, discount_percentage, rating, rating_count),
TRY_CAST(REPLACE(REPLACE(discounted_price, ',', ''), '₹', '') AS DOUBLE) AS discounted_price,
TRY_CAST(REPLACE(REPLACE(actual_price, ',', ''), '₹', '') AS DOUBLE) AS actual_price,
TRY_CAST(REPLACE(discount_percentage, '%', '') AS DOUBLE) AS discount_percentage,
TRY_CAST(REPLACE(rating, '|', '') AS DOUBLE) AS rating,
TRY_CAST(REPLACE(rating_count, ',', '') AS BIGINT) AS rating_count
FROM read_csv_auto(?)
) TO ? (FORMAT PARQUET);
""",
    [str(SOURCE_FILE), str(BRONZE_FILE)],
)

print(f"Bronze data written to {BRONZE_FILE}")


# Silver layer transformations
# 1NF Normalization
con.execute(
    """
COPY (
    SELECT
        * EXCLUDE (
            user_id,
            user_name,
            review_id,
            review_title,
            review_content
        ), 
        UNNEST(STRING_SPLIT(TRIM(user_id), ',')) AS user_id,
        UNNEST(STRING_SPLIT(TRIM(user_name), ',')) AS user_name,
        UNNEST(STRING_SPLIT(TRIM(review_id), ',')) AS review_id,
        UNNEST(STRING_SPLIT(TRIM(review_title), ',')) AS review_title,
        UNNEST(STRING_SPLIT(TRIM(review_content), ',')) AS review_content            
    FROM read_parquet(?) AS P
)
TO ?
(FORMAT PARQUET);
""",
    [str(BRONZE_FILE), str(SILVER_FILE)],
)


# Remove NULL values from the silver snapshot
con.execute(
    """
COPY (
    SELECT *
    FROM read_parquet(?)
    WHERE user_id IS NOT NULL
        AND user_name IS NOT NULL
        AND review_id IS NOT NULL
        AND review_title IS NOT NULL
        AND review_content IS NOT NULL
        AND rating IS NOT NULL
        AND rating_count IS NOT NULL
)
TO ?
(FORMAT PARQUET);
""",
    [str(SILVER_FILE), str(SILVER_FILE)],
)

print(f"Silver data written to {SILVER_FILE}")

con.close()
