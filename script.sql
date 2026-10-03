-- Enunciado 13
DO $$ 
DECLARE 
    -- Único cursor não vinculado 
    c_relatorio     REFCURSOR; 
    
    -- Variável para guardar o nome da dimensão 
    v_dimensao      TEXT; 
    v_sql           TEXT; 
    
    -- Variáveis de métricas
    v_total_receita NUMERIC(12,2); 
    v_valor         TEXT; 
    v_vendas        BIGINT; 
    v_receita       NUMERIC(12,2); 
    v_percentual    NUMERIC(5,2); 
    
    -- Contadores
    v_posicao       INT; 
    v_linhas_dim    INT; 
    v_linhas_total  INT := 0; 

BEGIN 
    --  Calcula a receita total da fato antes do laço
    SELECT SUM(total_spent) 
    INTO v_total_receita 
    FROM dw.fact_sales; 

    -- Laço numérico tradicional 
    FOR i IN 1..3 LOOP 
        
        -- Atribui o nome da dimensão da vez mantendo a ordem obrigatória
        IF i = 1 THEN 
            v_dimensao := 'item'; 
        ELSIF i = 2 THEN 
            v_dimensao := 'payment'; 
        ELSE 
            v_dimensao := 'location'; 
        END IF; 

        v_posicao    := 0; 
        v_linhas_dim := 0; 

        -- Consulta dinâmica por v_dimensao
        v_sql := 
            'SELECT d.' || v_dimensao || ', COUNT(*), SUM(f.total_spent) ' || 
            'FROM dw.fact_sales f ' || 
            'JOIN dw.dim_' || v_dimensao || ' d ON d.' || v_dimensao || '_sk = f.' || v_dimensao || '_sk ' || 
            'GROUP BY d.' || v_dimensao || ' ' || 
            'ORDER BY SUM(f.total_spent) DESC'; 

        --  Abertura do cursor 
        OPEN c_relatorio FOR EXECUTE v_sql; 
        
        LOOP 
            
            FETCH c_relatorio INTO v_valor, v_vendas, v_receita; 
            
            
            EXIT WHEN NOT FOUND; 
            
            v_posicao    := v_posicao + 1; 
            v_linhas_dim := v_linhas_dim + 1; 
            v_percentual := ROUND((v_receita / v_total_receita) * 100, 2); 
            
            
            RAISE NOTICE '% | % - %: % vendas, receita % (% %% do total)', 
                v_dimensao, v_posicao, v_valor, v_vendas, v_receita, v_percentual; 
        END LOOP; 

        --  Fechamento do cursor 
        CLOSE c_relatorio; 

        --  Relatório de linhas por dimensão
        RAISE NOTICE 'Total de linhas lidas na dimensão %: %', v_dimensao, v_linhas_dim; 
       
        
        v_linhas_total := v_linhas_total + v_linhas_dim; 
    END LOOP; 

    --  Relatório do total geral de linhas lidas
    RAISE NOTICE 'Total geral de linhas lidas: %', v_linhas_total; 

END; 
$$;


-- Enunciado 12
DROP TABLE IF EXISTS dw.fact_sales CASCADE;

CREATE TABLE dw.fact_sales (
    transaction_nk VARCHAR(20) PRIMARY KEY,
    date_sk INTEGER NOT NULL REFERENCES dw.dim_date(date_sk),
    item_sk INTEGER NOT NULL REFERENCES dw.dim_item(item_sk),
    payment_sk INTEGER NOT NULL REFERENCES dw.dim_payment(payment_sk),
    location_sk INTEGER NOT NULL REFERENCES dw.dim_location(location_sk),
    quantity INTEGER NOT NULL,
    price_per_unit NUMERIC(6,2) NOT NULL,
    total_spent NUMERIC(8,2) NOT NULL
);

CREATE INDEX ix_fs_date ON dw.fact_sales(date_sk);
CREATE INDEX ix_fs_item ON dw.fact_sales(item_sk);
CREATE INDEX ix_fs_payment ON dw.fact_sales(payment_sk);
CREATE INDEX ix_fs_location ON dw.fact_sales(location_sk);

TRUNCATE TABLE dw.fact_sales;

INSERT INTO dw.fact_sales (
    transaction_nk, date_sk, item_sk, payment_sk, location_sk, quantity, price_per_unit, total_spent
)
SELECT
    s.transaction_id,
    CAST(TO_CHAR(s.transaction_date, 'YYYYMMDD') AS INTEGER),
    di.item_sk,
    dp.payment_sk,
    dl.location_sk,
    s.quantity,
    s.price_per_unit,
    s.total_spent
FROM staging.cafe_sales s
JOIN dw.dim_item di ON di.item = s.item
JOIN dw.dim_payment dp ON dp.payment = s.payment_method
JOIN dw.dim_location dl ON dl.location = s.location;

SELECT 
    (SELECT COUNT(*) FROM staging.cafe_sales) AS linhas_staging,
    (SELECT COUNT(*) FROM dw.fact_sales) AS linhas_fato,
    (SELECT SUM(total_spent) FROM staging.cafe_sales) AS soma_staging,
    (SELECT SUM(total_spent) FROM dw.fact_sales) AS soma_fato;



-- Enunciado 11
DROP TABLE IF EXISTS dw.dim_item CASCADE;
CREATE TABLE dw.dim_item (
    item_sk SERIAL PRIMARY KEY,
    item VARCHAR(20) NOT NULL UNIQUE,
    category VARCHAR(10) NOT NULL
);

DROP TABLE IF EXISTS dw.dim_payment CASCADE;
CREATE TABLE dw.dim_payment (
    payment_sk SERIAL PRIMARY KEY,
    payment VARCHAR(20) NOT NULL UNIQUE
);

DROP TABLE IF EXISTS dw.dim_location CASCADE;
CREATE TABLE dw.dim_location (
    location_sk SERIAL PRIMARY KEY,
    location VARCHAR(20) NOT NULL UNIQUE
);

INSERT INTO dw.dim_item (item, category)
SELECT DISTINCT s.item, c.category
FROM staging.cafe_sales s
JOIN staging.cardapio c ON c.item = s.item;

INSERT INTO dw.dim_payment (payment)
SELECT DISTINCT payment_method FROM staging.cafe_sales;

INSERT INTO dw.dim_location (location)
SELECT DISTINCT location FROM staging.cafe_sales;

SELECT 'item' AS dimensao, COUNT(*) AS linhas FROM dw.dim_item
UNION ALL
SELECT 'payment', COUNT(*) FROM dw.dim_payment
UNION ALL
SELECT 'location', COUNT(*) FROM dw.dim_location;



-- Enunciado 10
SELECT MIN(transaction_date), MAX(transaction_date) FROM staging.cafe_sales;

DROP TABLE IF EXISTS dw.dim_date CASCADE;

CREATE TABLE dw.dim_date (
    date_sk INTEGER PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    day SMALLINT NOT NULL,
    month SMALLINT NOT NULL,
    month_name VARCHAR(15) NOT NULL,
    quarter SMALLINT NOT NULL,
    year SMALLINT NOT NULL,
    day_of_week VARCHAR(15) NOT NULL,
    is_weekend BOOLEAN NOT NULL
);

INSERT INTO dw.dim_date
SELECT
    CAST(TO_CHAR(d, 'YYYYMMDD') AS INTEGER),
    d::DATE,
    EXTRACT(DAY FROM d)::SMALLINT,
    EXTRACT(MONTH FROM d)::SMALLINT,
    TO_CHAR(d, 'TMMonth'),
    EXTRACT(QUARTER FROM d)::SMALLINT,
    EXTRACT(YEAR FROM d)::SMALLINT,
    TO_CHAR(d, 'TMDay'),
    EXTRACT(DOW FROM d) IN (0, 6)
FROM generate_series(DATE '2023-01-01', DATE '2023-12-31', INTERVAL '1 day') g(d);

SELECT COUNT(*) FROM dw.dim_date;

-- Enunciado 9
DROP TABLE IF EXISTS staging.cafe_sales CASCADE;

CREATE TABLE staging.cafe_sales (
    transaction_id   VARCHAR(20) PRIMARY KEY,
    item             VARCHAR(20) NOT NULL,
    quantity         INTEGER NOT NULL CHECK (quantity > 0),
    price_per_unit   NUMERIC(6,2) NOT NULL CHECK (price_per_unit > 0),
    total_spent      NUMERIC(8,2) NOT NULL,
    payment_method   VARCHAR(20) NOT NULL,
    location         VARCHAR(20) NOT NULL,
    transaction_date DATE NOT NULL
);

TRUNCATE TABLE staging.cafe_sales;

INSERT INTO staging.cafe_sales (
    transaction_id,
    item,
    quantity,
    price_per_unit,
    total_spent,
    payment_method,
    location,
    transaction_date
)
SELECT 
    transaction_id,
    item,
    quantity,
    price_per_unit,
    total_spent,
    payment_method,
    location,
    transaction_date
FROM staging.cafe_tipada
WHERE transaction_id IS NOT NULL
  AND item IS NOT NULL
  AND quantity IS NOT NULL
  AND price_per_unit IS NOT NULL
  AND total_spent IS NOT NULL
  AND payment_method IS NOT NULL
  AND location IS NOT NULL
  AND transaction_date IS NOT NULL;

-- Consulta de auditoria e comparação de linhas entre tipada e limpa
SELECT 
    (SELECT COUNT(*) FROM staging.cafe_tipada) AS linhas_tipada,
    (SELECT COUNT(*) FROM staging.cafe_sales) AS linhas_limpas,
    ((SELECT COUNT(*) FROM staging.cafe_tipada) - (SELECT COUNT(*) FROM staging.cafe_sales)) AS descartadas;

-- Enunciado 8 
-- R1: preco nulo e item conhecido -> preco do item no cardapio
UPDATE staging.cafe_tipada t
SET price_per_unit = (SELECT c.price FROM staging.cardapio c WHERE c.item = t.item)
WHERE t.price_per_unit IS NULL AND t.item IS NOT NULL;

-- R2: preco nulo, quantidade e total conhecidos -> preco = total / quantidade
UPDATE staging.cafe_tipada
SET price_per_unit = total_spent / quantity
WHERE price_per_unit IS NULL AND quantity IS NOT NULL AND total_spent IS NOT NULL;

-- R3: quantidade nula, preco e total conhecidos -> quantidade = total / preco
UPDATE staging.cafe_tipada
SET quantity = ROUND(total_spent / price_per_unit)
WHERE quantity IS NULL AND price_per_unit IS NOT NULL AND total_spent IS NOT NULL;

-- R4: total nulo, quantidade e preco conhecidos -> total = quantidade x preco
UPDATE staging.cafe_tipada
SET total_spent = quantity * price_per_unit
WHERE total_spent IS NULL AND quantity IS NOT NULL AND price_per_unit IS NOT NULL;

-- R5: item nulo e preço conhecido, pertencente a um único item do cardápio -> item <- item do cardápio
UPDATE staging.cafe_tipada
SET item = (
    SELECT c.item 
    FROM staging.cardapio c 
    WHERE c.price = staging.cafe_tipada.price_per_unit
)

WHERE item IS NULL 
  AND price_per_unit IN (
      SELECT price 
      FROM staging.cardapio 
      GROUP BY price 
      HAVING COUNT(*) = 1
  );


-- R6: forma de pagamento ou local nulos -> substituir por 'Unknown'
UPDATE staging.cafe_tipada
SET payment_method = 'Unknown'
WHERE payment_method IS NULL;

UPDATE staging.cafe_tipada
SET location = 'Unknown'
WHERE location IS NULL;


-- Enuncaido 7
DROP TABLE IF EXISTS staging.cardapio CASCADE;

CREATE TABLE staging.cardapio (
    item     VARCHAR(20) PRIMARY KEY,
    price    NUMERIC(6,2) NOT NULL,
    category VARCHAR(10) NOT NULL
);

INSERT INTO staging.cardapio (item, price, category) VALUES
('Cookie',   1.00, 'Comida'),
('Tea',      1.50, 'Bebida'),
('Coffee',   2.00, 'Bebida'),
('Cake',     3.00, 'Comida'),
('Juice',    3.00, 'Bebida'),
('Sandwich', 4.00, 'Comida'),
('Smoothie', 4.00, 'Bebida'),
('Salad',    5.00, 'Comida');

SELECT * FROM staging.cardapio


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