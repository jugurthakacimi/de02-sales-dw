SET VARIABLE SOURCE_FILE = 'data/raw/amazon.csv';
SET VARIABLE BRONZE_FILE = 'data/bronze/amazon_bronze.parquet';

COPY (SELECT * FROM read_csv_auto($SOURCE_FILE)) TO $BRONZE_FILE (FORMAT PARQUET);