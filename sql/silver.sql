SET VARIABLE BRONZE_FILE = 'data/bronze/amazon_bronze.parquet';
SET VARIABLE SILVER_FILE = 'data/silver/amazon_silver.parquet';

-- Format columns
COPY (SELECT * exclude (discounted_price, actual_price, discount_percentage, rating, rating_count),
TRY_CAST(REPLACE(REPLACE(discounted_price, ',', ''), '₹', '') AS DOUBLE) AS discounted_price,
TRY_CAST(REPLACE(REPLACE(actual_price, ',', ''), '₹', '') AS DOUBLE) AS actual_price,
TRY_CAST(REPLACE(discount_percentage, '%', '') AS DOUBLE) AS discount_percentage,
TRY_CAST(REPLACE(rating, '|', '') AS DOUBLE) AS rating,
TRY_CAST(REPLACE(rating_count, ',', '') AS BIGINT) AS rating_count
FROM read_parquet($BRONZE_FILE)
) TO $SILVER_FILE (FORMAT PARQUET);

-- 1NF Normalization
COPY (
    SELECT * EXCLUDE (
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
    FROM read_parquet($SILVER_FILE)
) TO $SILVER_FILE (FORMAT PARQUET);

-- Remove NULL values from the silver snapshot
COPY (
    SELECT * FROM read_parquet($SILVER_FILE)
    WHERE user_id IS NOT NULL
        AND user_name IS NOT NULL
        AND review_id IS NOT NULL
        AND review_title IS NOT NULL
        AND review_content IS NOT NULL
        AND rating IS NOT NULL
        AND rating_count IS NOT NULL
) 
TO $SILVER_FILE (FORMAT PARQUET);