-- 1. Топ-10 найкращих продуктів за доходом
SELECT product_id, SUM(sale_price) AS sale
FROM orders
GROUP BY product_id
ORDER BY sale DESC
LIMIT 10;


-- 2. Топ-5 найпопулярніших товарів у кожному регіоні
WITH cte AS (
    SELECT region, product_id, SUM(sale_price) AS sale
    FROM orders
    GROUP BY region, product_id
)
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY region ORDER BY sale DESC) AS rn
    FROM cte
)
WHERE rn <= 5;


-- 3. Порівняння продажів по місяцях: 2022 vs 2023
WITH cte AS (
    SELECT
        strftime('%Y', order_date) AS order_year,
        strftime('%m', order_date) AS order_month,
        SUM(sale_price) AS sales
    FROM orders
    GROUP BY order_year, order_month
)
SELECT
    order_month,
    SUM(CASE WHEN order_year = '2022' THEN sales ELSE 0 END) AS sales_2022,
    SUM(CASE WHEN order_year = '2023' THEN sales ELSE 0 END) AS sales_2023
FROM cte
GROUP BY order_month
ORDER BY order_month;


-- 4. Для кожної категорії: місяць з найвищими продажами
WITH cte1 AS (
    SELECT
        category,
        strftime('%Y%m', order_date) AS order_year_month,
        SUM(sale_price) AS sales
    FROM orders
    GROUP BY category, order_year_month
)
SELECT category, order_year_month, sales
FROM (
    SELECT category, order_year_month, sales,
           RANK() OVER (PARTITION BY category ORDER BY sales DESC) AS rn
    FROM cte1
)
WHERE rn = 1;


-- 5. Підкатегорія з найбільшим зростанням прибутку у 2023 порівняно з 2022
WITH cte1 AS (
    SELECT
        sub_category,
        strftime('%Y', order_date) AS order_year,
        SUM(profit) AS total_profit
    FROM orders
    GROUP BY sub_category, order_year
),
cte2 AS (
    SELECT
        sub_category,
        SUM(CASE WHEN order_year = '2022' THEN total_profit ELSE 0 END) AS profit_2022,
        SUM(CASE WHEN order_year = '2023' THEN total_profit ELSE 0 END) AS profit_2023
    FROM cte1
    GROUP BY sub_category
)
SELECT
    *,
    ROUND((profit_2023 - profit_2022) * 100.0 / NULLIF(profit_2022, 0), 2) AS growth_percent
FROM cte2
ORDER BY growth_percent DESC;
