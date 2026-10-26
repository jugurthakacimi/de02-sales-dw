SET VARIABLE SILVER_FILE = 'data/silver/amazon_silver.parquet';
SET VARIABLE GOLD_PRODUCTS_FILE='data/gold/amazon_gold_products.parquet';
SET VARIABLE GOLD_USERS_FILE='data/gold/amazon_gold_users.parquet';
SET VARIABLE GOLD_REVIEWS_FILE='data/gold/amazon_gold_reviews.parquet';

-- Create gold schema
CREATE SCHEMA IF NOT EXISTS gold;

-- Copy products data to gold products parquet file
COPY(SELECT DISTINCT 
    product_id,
    product_name,
    category,
    about_product,
    img_link,
    product_link,
    discounted_price,
    actual_price,
    discount_percentage,
    rating,
    rating_count
FROM read_parquet($SILVER_FILE)
) TO $GOLD_PRODUCTS_FILE (FORMAT PARQUET);

-- Copy users data to gold users parquet file
COPY(SELECT DISTINCT 
    user_id,
    user_name
FROM read_parquet($SILVER_FILE)
) TO $GOLD_USERS_FILE (FORMAT PARQUET);

-- Copy reviews data to gold reviews parquet file
COPY(SELECT DISTINCT 
  review_id,
  review_title,
  review_content,
  user_id,
  product_id
FROM read_parquet($SILVER_FILE)
) TO $GOLD_REVIEWS_FILE (FORMAT PARQUET);

-- Create products gold table
CREATE TABLE IF NOT EXISTS gold.products AS
SELECT DISTINCT * FROM read_parquet($GOLD_PRODUCTS_FILE);

-- Create users gold table
CREATE TABLE IF NOT EXISTS gold.users AS
SELECT DISTINCT * FROM read_parquet($GOLD_USERS_FILE);

-- Create reviews gold table
CREATE TABLE IF NOT EXISTS gold.reviews AS
SELECT DISTINCT * FROM read_parquet($GOLD_REVIEWS_FILE);