/*
Project: Sales Channel Performance Analytics Dashboard
Dataset: AdventureWorksDW2022
File: 03_business_kpis.sql

Purpose:
This script performs business KPI analysis using the cleaned SQL views.
It supports Power BI dashboard design by analyzing sales, profit, channels,
products, regions, trends, and customer segments.
*/

USE AdventureWorksDW2022;
GO


/* ============================================================
   1. Overall sales KPIs
   ============================================================ */

SELECT
    COUNT(DISTINCT CONCAT(sales_channel, '-', sales_order_number)) AS total_orders,
    COUNT(*) AS total_order_lines,
    SUM(order_quantity) AS total_quantity_sold,
    SUM(sales_amount) AS total_sales,
    SUM(total_product_cost) AS total_cost,
    SUM(gross_profit) AS total_gross_profit,
    CASE 
        WHEN SUM(sales_amount) = 0 THEN NULL
        ELSE SUM(gross_profit) / SUM(sales_amount)
    END AS gross_profit_margin,
    SUM(sales_amount) / COUNT(DISTINCT CONCAT(sales_channel, '-', sales_order_number)) AS average_order_value
FROM dbo.vw_fact_sales;
GO


/* ============================================================
   2. Sales KPIs by sales channel
   ============================================================ */

SELECT
    sales_channel,
    COUNT(DISTINCT sales_order_number) AS total_orders,
    COUNT(*) AS total_order_lines,
    SUM(order_quantity) AS total_quantity_sold,
    SUM(sales_amount) AS total_sales,
    SUM(total_product_cost) AS total_cost,
    SUM(gross_profit) AS total_gross_profit,
    CASE 
        WHEN SUM(sales_amount) = 0 THEN NULL
        ELSE SUM(gross_profit) / SUM(sales_amount)
    END AS gross_profit_margin,
    SUM(sales_amount) / COUNT(DISTINCT sales_order_number) AS average_order_value
FROM dbo.vw_fact_sales
GROUP BY sales_channel
ORDER BY total_sales DESC;
GO


/* ============================================================
   3. Monthly sales trend by channel
   ============================================================ */

SELECT
    d.calendar_year,
    d.month_number,
    d.month_name,
    fs.sales_channel,
    SUM(fs.sales_amount) AS monthly_sales,
    SUM(fs.gross_profit) AS monthly_gross_profit,
    SUM(fs.order_quantity) AS monthly_quantity_sold
FROM dbo.vw_fact_sales fs
LEFT JOIN dbo.vw_dim_date d
    ON fs.order_date_key = d.date_key
GROUP BY
    d.calendar_year,
    d.month_number,
    d.month_name,
    fs.sales_channel
ORDER BY
    d.calendar_year,
    d.month_number,
    fs.sales_channel;
GO


/* ============================================================
   4. Year-over-year sales growth by channel
   ============================================================ */

WITH annual_sales AS (
    SELECT
        d.calendar_year,
        fs.sales_channel,
        SUM(fs.sales_amount) AS total_sales
    FROM dbo.vw_fact_sales fs
    LEFT JOIN dbo.vw_dim_date d
        ON fs.order_date_key = d.date_key
    GROUP BY
        d.calendar_year,
        fs.sales_channel
),

annual_sales_with_lag AS (
    SELECT
        calendar_year,
        sales_channel,
        total_sales,
        LAG(total_sales) OVER (
            PARTITION BY sales_channel
            ORDER BY calendar_year
        ) AS previous_year_sales
    FROM annual_sales
)

SELECT
    calendar_year,
    sales_channel,
    total_sales,
    previous_year_sales,
    total_sales - previous_year_sales AS yoy_sales_change,
    CASE
        WHEN previous_year_sales IS NULL OR previous_year_sales = 0 THEN NULL
        ELSE (total_sales - previous_year_sales) / previous_year_sales
    END AS yoy_sales_growth_rate
FROM annual_sales_with_lag
ORDER BY
    sales_channel,
    calendar_year;
GO


/* ============================================================
   5. Sales performance by product category
   ============================================================ */

SELECT
    p.product_category,
    p.product_subcategory,
    fs.sales_channel,
    SUM(fs.order_quantity) AS total_quantity_sold,
    SUM(fs.sales_amount) AS total_sales,
    SUM(fs.gross_profit) AS total_gross_profit,
    CASE
        WHEN SUM(fs.sales_amount) = 0 THEN NULL
        ELSE SUM(fs.gross_profit) / SUM(fs.sales_amount)
    END AS gross_profit_margin
FROM dbo.vw_fact_sales fs
LEFT JOIN dbo.vw_dim_product p
    ON fs.product_key = p.product_key
GROUP BY
    p.product_category,
    p.product_subcategory,
    fs.sales_channel
ORDER BY
    total_sales DESC;
GO


/* ============================================================
   6. Top 20 products by sales
   ============================================================ */

SELECT TOP 20
    p.product_name,
    p.product_category,
    p.product_subcategory,
    fs.sales_channel,
    SUM(fs.order_quantity) AS total_quantity_sold,
    SUM(fs.sales_amount) AS total_sales,
    SUM(fs.gross_profit) AS total_gross_profit,
    CASE
        WHEN SUM(fs.sales_amount) = 0 THEN NULL
        ELSE SUM(fs.gross_profit) / SUM(fs.sales_amount)
    END AS gross_profit_margin
FROM dbo.vw_fact_sales fs
LEFT JOIN dbo.vw_dim_product p
    ON fs.product_key = p.product_key
GROUP BY
    p.product_name,
    p.product_category,
    p.product_subcategory,
    fs.sales_channel
ORDER BY
    total_sales DESC;
GO


/* ============================================================
   7. Sales performance by sales territory
   ============================================================ */

SELECT
    t.sales_territory_group,
    t.sales_territory_country,
    t.sales_territory_region,
    fs.sales_channel,
    COUNT(DISTINCT fs.sales_order_number) AS total_orders,
    SUM(fs.sales_amount) AS total_sales,
    SUM(fs.gross_profit) AS total_gross_profit,
    CASE
        WHEN SUM(fs.sales_amount) = 0 THEN NULL
        ELSE SUM(fs.gross_profit) / SUM(fs.sales_amount)
    END AS gross_profit_margin
FROM dbo.vw_fact_sales fs
LEFT JOIN dbo.vw_dim_sales_territory t
    ON fs.sales_territory_key = t.sales_territory_key
GROUP BY
    t.sales_territory_group,
    t.sales_territory_country,
    t.sales_territory_region,
    fs.sales_channel
ORDER BY
    total_sales DESC;
GO


/* ============================================================
   8. Internet sales customer segment analysis
   ============================================================ */

SELECT
    c.income_group,
    c.gender,
    c.marital_status,
    c.education,
    c.occupation,
    COUNT(DISTINCT fs.customer_key) AS customer_count,
    COUNT(DISTINCT fs.sales_order_number) AS total_orders,
    SUM(fs.sales_amount) AS total_sales,
    SUM(fs.gross_profit) AS total_gross_profit,
    CASE
        WHEN COUNT(DISTINCT fs.customer_key) = 0 THEN NULL
        ELSE SUM(fs.sales_amount) / COUNT(DISTINCT fs.customer_key)
    END AS sales_per_customer
FROM dbo.vw_fact_sales fs
LEFT JOIN dbo.vw_dim_customer c
    ON fs.customer_key = c.customer_key
WHERE fs.sales_channel = 'Internet Sales'
GROUP BY
    c.income_group,
    c.gender,
    c.marital_status,
    c.education,
    c.occupation
ORDER BY
    total_sales DESC;
GO


/* ============================================================
   9. Sales contribution by product category
   ============================================================ */

WITH category_sales AS (
    SELECT
        p.product_category,
        SUM(fs.sales_amount) AS category_sales
    FROM dbo.vw_fact_sales fs
    LEFT JOIN dbo.vw_dim_product p
        ON fs.product_key = p.product_key
    GROUP BY
        p.product_category
),

total_sales AS (
    SELECT
        SUM(sales_amount) AS overall_sales
    FROM dbo.vw_fact_sales
)

SELECT
    cs.product_category,
    cs.category_sales,
    ts.overall_sales,
    cs.category_sales / ts.overall_sales AS sales_contribution_rate
FROM category_sales cs
CROSS JOIN total_sales ts
ORDER BY
    cs.category_sales DESC;
GO


/* ============================================================
   10. Profitability ranking by product category
   ============================================================ */

SELECT
    p.product_category,
    p.product_subcategory,
    SUM(fs.sales_amount) AS total_sales,
    SUM(fs.total_product_cost) AS total_cost,
    SUM(fs.gross_profit) AS total_gross_profit,
    CASE
        WHEN SUM(fs.sales_amount) = 0 THEN NULL
        ELSE SUM(fs.gross_profit) / SUM(fs.sales_amount)
    END AS gross_profit_margin
FROM dbo.vw_fact_sales fs
LEFT JOIN dbo.vw_dim_product p
    ON fs.product_key = p.product_key
GROUP BY
    p.product_category,
    p.product_subcategory
ORDER BY
    gross_profit_margin DESC;
GO