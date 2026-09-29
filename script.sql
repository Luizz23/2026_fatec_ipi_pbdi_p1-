-- Enunciado 5
SELECT 'item' AS coluna,
       COUNT(*) FILTER (WHERE TRIM(item) = 'ERROR') AS qtd_error,
	   COUNT (TRIM(item) = 'UNKNOWN')  AS qtd_unknown,
       COUNT (TRIM(item) = '' OR item IS NULL) AS qtd_vazio
FROM raw.cafe_sales
UNION ALL
SELECT 'quantity' AS coluna,
       COUNT(*) FILTER (WHERE TRIM(quantity) = 'ERROR') AS qtd_error,
	   COUNT (TRIM(quantity) = 'UNKNOWN')  AS qtd_unknown,
       COUNT (TRIM(quantity) = '' OR quantity IS NULL) AS qtd_vazio
FROM raw.cafe_sales
UNION ALL
SELECT 'price_per_unit' AS coluna,
       COUNT(*) FILTER (WHERE TRIM(price_per_unit) = 'ERROR') AS qtd_error,
	   COUNT (TRIM(price_per_unit) = 'UNKNOWN')  AS qtd_unknown,
       COUNT (TRIM(price_per_unit) = '' OR price_per_unit IS NULL) AS qtd_vazio
FROM raw.cafe_sales
UNION ALL
SELECT 'total_spent' AS coluna,
       COUNT(*) FILTER (WHERE TRIM(total_spent) = 'ERROR') AS qtd_error,
	   COUNT (TRIM(total_spent) = 'UNKNOWN')  AS qtd_unknown,
       COUNT (TRIM(total_spent) = '' OR total_spent IS NULL) AS qtd_vazio
FROM raw.cafe_sales
UNION ALL
SELECT 'payment_method' AS coluna,
       COUNT(*) FILTER (WHERE TRIM(total_spent) = 'ERROR') AS qtd_error,
	   COUNT (TRIM(total_spent) = 'UNKNOWN')  AS qtd_unknown,
       COUNT (TRIM(total_spent) = '' OR total_spent IS NULL) AS qtd_vazio
FROM raw.cafe_sales
UNION ALL
SELECT 'location' AS coluna,
       COUNT(*) FILTER (WHERE TRIM(location) = 'ERROR') AS qtd_error,
	   COUNT (TRIM(location) = 'UNKNOWN')  AS qtd_unknown,
       COUNT (TRIM(location) = '' OR location IS NULL) AS qtd_vazio
FROM raw.cafe_sales
UNION ALL
SELECT 'transaction_date' AS coluna,
       COUNT(*) FILTER (WHERE TRIM(transaction_date) = 'ERROR') AS qtd_error,
	   COUNT (TRIM(transaction_date) = 'UNKNOWN')  AS qtd_unknown,
       COUNT (TRIM(transaction_date) = '' OR transaction_date IS NULL) AS qtd_vazio
FROM raw.cafe_sales




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