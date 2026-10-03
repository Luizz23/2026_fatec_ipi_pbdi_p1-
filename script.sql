

-- Enunciado 6
DROP TABLE IF EXISTS staging.cafe_tipada CASCADE;
 
CREATE TABLE staging.cafe_tipada (
    transaction_id VARCHAR(20) PRIMARY KEY,
    item VARCHAR(20),
    quantity INTEGER,
    price_per_unit NUMERIC(6,2),
    total_spent NUMERIC(8,2),
    payment_method VARCHAR(20),
    location VARCHAR(20),
    transaction_date DATE
);
 
TRUNCATE TABLE staging.cafe_tipada;
 
INSERT INTO staging.cafe_tipada (
    transaction_id, item, quantity, price_per_unit,
    total_spent, payment_method, location, transaction_date
)
SELECT 
    TRIM(transaction_id),
    CASE WHEN TRIM(item) IN ('', 'ERROR', 'UNKNOWN') THEN NULL ELSE TRIM(item) END,
    CAST(CASE WHEN TRIM(quantity) IN ('', 'ERROR', 'UNKNOWN') THEN NULL ELSE TRIM(quantity) END AS INTEGER),
    CAST(CASE WHEN TRIM(price_per_unit) IN ('', 'ERROR', 'UNKNOWN') THEN NULL ELSE TRIM(price_per_unit) END AS NUMERIC(6,2)),
    CAST(CASE WHEN TRIM(total_spent) IN ('', 'ERROR', 'UNKNOWN') THEN NULL ELSE TRIM(total_spent) END AS NUMERIC(8,2)),
    CASE WHEN TRIM(payment_method) IN ('', 'ERROR', 'UNKNOWN') THEN NULL ELSE TRIM(payment_method) END,
    CASE WHEN TRIM(location) IN ('', 'ERROR', 'UNKNOWN') THEN NULL ELSE TRIM(location) END,
    TO_DATE(CASE WHEN TRIM(transaction_date) IN ('', 'ERROR', 'UNKNOWN') THEN NULL ELSE TRIM(transaction_date) END, 'YYYY-MM-DD')
FROM raw.cafe_sales;
 
SELECT 
    COUNT(*) FILTER (WHERE item IS NULL) AS null_item,
    COUNT(*) FILTER (WHERE quantity IS NULL) AS null_quantity,
    COUNT(*) FILTER (WHERE price_per_unit IS NULL) AS null_price,
    COUNT(*) FILTER (WHERE total_spent IS NULL) AS null_total,
    COUNT(*) FILTER (WHERE payment_method IS NULL) AS null_payment,
    COUNT(*) FILTER (WHERE location IS NULL) AS null_location,
    COUNT(*) FILTER (WHERE transaction_date IS NULL) AS null_date
FROM staging.cafe_tipada;


-- Enunciado 5
SELECT 'item' AS coluna,
       COUNT(*) FILTER (WHERE TRIM(item) = 'ERROR') AS qtd_error,
       COUNT(*) FILTER (WHERE TRIM(item) = 'UNKNOWN') AS qtd_unknown,
       COUNT(*) FILTER (WHERE TRIM(item) = '' OR item IS NULL) AS qtd_vazio
FROM raw.cafe_sales
UNION ALL
SELECT 'quantity',
       COUNT(*) FILTER (WHERE TRIM(quantity) = 'ERROR'),
       COUNT(*) FILTER (WHERE TRIM(quantity) = 'UNKNOWN'),
       COUNT(*) FILTER (WHERE TRIM(quantity) = '' OR quantity IS NULL)
FROM raw.cafe_sales
UNION ALL
SELECT 'price_per_unit',
       COUNT(*) FILTER (WHERE TRIM(price_per_unit) = 'ERROR'),
       COUNT(*) FILTER (WHERE TRIM(price_per_unit) = 'UNKNOWN'),
       COUNT(*) FILTER (WHERE TRIM(price_per_unit) = '' OR price_per_unit IS NULL)
FROM raw.cafe_sales
UNION ALL
SELECT 'total_spent',
       COUNT(*) FILTER (WHERE TRIM(total_spent) = 'ERROR'),
       COUNT(*) FILTER (WHERE TRIM(total_spent) = 'UNKNOWN'),
       COUNT(*) FILTER (WHERE TRIM(total_spent) = '' OR total_spent IS NULL)
FROM raw.cafe_sales
UNION ALL
SELECT 'payment_method',
       COUNT(*) FILTER (WHERE TRIM(payment_method) = 'ERROR'),
       COUNT(*) FILTER (WHERE TRIM(payment_method) = 'UNKNOWN'),
       COUNT(*) FILTER (WHERE TRIM(payment_method) = '' OR payment_method IS NULL)
FROM raw.cafe_sales
UNION ALL
SELECT 'location',
       COUNT(*) FILTER (WHERE TRIM(location) = 'ERROR'),
       COUNT(*) FILTER (WHERE TRIM(location) = 'UNKNOWN'),
       COUNT(*) FILTER (WHERE TRIM(location) = '' OR location IS NULL)
FROM raw.cafe_sales
UNION ALL
SELECT 'transaction_date',
       COUNT(*) FILTER (WHERE TRIM(transaction_date) = 'ERROR'),
       COUNT(*) FILTER (WHERE TRIM(transaction_date) = 'UNKNOWN'),
       COUNT(*) FILTER (WHERE TRIM(transaction_date) = '' OR transaction_date IS NULL)
FROM raw.cafe_sales;




-- Enunciado 4
--item
SELECT DISTINCT
	item,
	COUNT(*) AS total
FROM raw.cafe_sales
GROUP BY item
ORDER BY total DESC;

--payment_method
SELECT DISTINCT
	payment_method,
	COUNT(*) AS total
FROM raw.cafe_sales
GROUP BY payment_method
ORDER BY total DESC;

--location
SELECT DISTINCT
	location, 
	COUNT(*) AS total
FROM raw.cafe_sales
GROUP BY location
ORDER BY total DESC;



-- Enunciado 3
SELECT COUNT(*) FROM raw.cafe_sales;
SELECT COUNT (DISTINCT transaction_id) FROM raw.cafe_sales;


-- Enunciado 2
DROP TABLE IF EXISTS raw.cafe_sales CASCADE;

CREATE TABLE raw.cafe_sales (
    transaction_id TEXT,
    item TEXT,
    quantity TEXT,
    price_per_unit TEXT,
    total_spent TEXT,
    payment_method TEXT,
    location TEXT,
    transaction_date TEXT
);



-- Enunciado 1

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS dw;

SELECT schema_name
FROM information_schema.schemata
WHERE schema_name IN ('raw', 'staging', 'dw');