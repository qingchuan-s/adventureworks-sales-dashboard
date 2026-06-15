/* 
Project: Sales Channel Performance Analytics Dashboard
Dataset: AdventureWorksDW2022
File: 01_data_exploration.sql

Purpose:
This script explores the database structure, key fact tables, dimension tables,
date coverage, row counts, and basic data quality checks before building
Power BI data models and business KPIs.
*/

USE AdventureWorksDW2022;
GO


/* ============================================================
   1. List all user tables in the database
   ============================================================ */

SELECT 
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN (
    'FactInternetSales',
    'FactResellerSales',
    'DimDate',
    'DimProduct',
    'DimCustomer',
    'DimGeography'
)
ORDER BY TABLE_NAME, ORDINAL_POSITION;

/* ============================================================
   2. Check row counts for key tables
   ============================================================ */

SELECT 'FactInternetSales' AS table_name, COUNT(*) AS row_count
FROM dbo.FactInternetSales

UNION ALL

SELECT 'FactResellerSales', COUNT(*)
FROM dbo.FactResellerSales

UNION ALL

SELECT 'DimDate', COUNT(*)
FROM dbo.DimDate

UNION ALL

SELECT 'DimProduct', COUNT(*)
FROM dbo.DimProduct

UNION ALL

SELECT 'DimProductSubcategory', COUNT(*)
FROM dbo.DimProductSubcategory

UNION ALL

SELECT 'DimProductCategory', COUNT(*)
FROM dbo.DimProductCategory

UNION ALL

SELECT 'DimCustomer', COUNT(*)
FROM dbo.DimCustomer

UNION ALL

SELECT 'DimGeography', COUNT(*)
FROM dbo.DimGeography;


/* ============================================================
   3. Explore sales date coverage
   ============================================================ */

SELECT
    'Internet Sales' AS sales_channel,
    MIN(OrderDate) AS first_order_date,
    MAX(OrderDate) AS last_order_date,
    COUNT(*) AS transaction_count
FROM dbo.FactInternetSales

UNION ALL

SELECT
    'Reseller Sales' AS sales_channel,
    MIN(OrderDate) AS first_order_date,
    MAX(OrderDate) AS last_order_date,
    COUNT(*) AS transaction_count
FROM dbo.FactResellerSales;


/* ============================================================
   4. Preview Internet Sales data
   ============================================================ */

SELECT TOP 20
    SalesOrderNumber,
    OrderDate,
    ProductKey,
    CustomerKey,
    SalesTerritoryKey,
    OrderQuantity,
    SalesAmount,
    TotalProductCost,
    TaxAmt,
    Freight
FROM dbo.FactInternetSales
ORDER BY OrderDate;


/* ============================================================
   5. Preview Reseller Sales data
   ============================================================ */

SELECT TOP 20
    SalesOrderNumber,
    OrderDate,
    ProductKey,
    ResellerKey,
    EmployeeKey,
    SalesTerritoryKey,
    OrderQuantity,
    SalesAmount,
    TotalProductCost,
    TaxAmt,
    Freight
FROM dbo.FactResellerSales
ORDER BY OrderDate;


/* ============================================================
   6. Basic sales amount checks
   ============================================================ */

SELECT
    'Internet Sales' AS sales_channel,
    COUNT(*) AS transaction_count,
    SUM(SalesAmount) AS total_sales,
    SUM(TotalProductCost) AS total_cost,
    SUM(SalesAmount - TotalProductCost) AS gross_profit,
    AVG(SalesAmount) AS avg_sales_amount,
    MIN(SalesAmount) AS min_sales_amount,
    MAX(SalesAmount) AS max_sales_amount
FROM dbo.FactInternetSales

UNION ALL

SELECT
    'Reseller Sales' AS sales_channel,
    COUNT(*) AS transaction_count,
    SUM(SalesAmount) AS total_sales,
    SUM(TotalProductCost) AS total_cost,
    SUM(SalesAmount - TotalProductCost) AS gross_profit,
    AVG(SalesAmount) AS avg_sales_amount,
    MIN(SalesAmount) AS min_sales_amount,
    MAX(SalesAmount) AS max_sales_amount
FROM dbo.FactResellerSales;


/* ============================================================
   7. Check missing values in key columns: Internet Sales
   ============================================================ */

SELECT
    SUM(CASE WHEN OrderDate IS NULL THEN 1 ELSE 0 END) AS missing_order_date,
    SUM(CASE WHEN ProductKey IS NULL THEN 1 ELSE 0 END) AS missing_product_key,
    SUM(CASE WHEN CustomerKey IS NULL THEN 1 ELSE 0 END) AS missing_customer_key,
    SUM(CASE WHEN SalesTerritoryKey IS NULL THEN 1 ELSE 0 END) AS missing_sales_territory_key,
    SUM(CASE WHEN SalesAmount IS NULL THEN 1 ELSE 0 END) AS missing_sales_amount,
    SUM(CASE WHEN TotalProductCost IS NULL THEN 1 ELSE 0 END) AS missing_total_product_cost
FROM dbo.FactInternetSales;


/* ============================================================
   8. Check missing values in key columns: Reseller Sales
   ============================================================ */

SELECT
    SUM(CASE WHEN OrderDate IS NULL THEN 1 ELSE 0 END) AS missing_order_date,
    SUM(CASE WHEN ProductKey IS NULL THEN 1 ELSE 0 END) AS missing_product_key,
    SUM(CASE WHEN ResellerKey IS NULL THEN 1 ELSE 0 END) AS missing_reseller_key,
    SUM(CASE WHEN SalesTerritoryKey IS NULL THEN 1 ELSE 0 END) AS missing_sales_territory_key,
    SUM(CASE WHEN SalesAmount IS NULL THEN 1 ELSE 0 END) AS missing_sales_amount,
    SUM(CASE WHEN TotalProductCost IS NULL THEN 1 ELSE 0 END) AS missing_total_product_cost
FROM dbo.FactResellerSales;


/* ============================================================
   9. Product hierarchy preview
   ============================================================ */

SELECT TOP 50
    p.ProductKey,
    p.EnglishProductName AS product_name,
    ps.EnglishProductSubcategoryName AS product_subcategory,
    pc.EnglishProductCategoryName AS product_category,
    p.Color,
    p.Size,
    p.StandardCost,
    p.ListPrice
FROM dbo.DimProduct p
LEFT JOIN dbo.DimProductSubcategory ps
    ON p.ProductSubcategoryKey = ps.ProductSubcategoryKey
LEFT JOIN dbo.DimProductCategory pc
    ON ps.ProductCategoryKey = pc.ProductCategoryKey
ORDER BY product_category, product_subcategory, product_name;


/* ============================================================
   10. Geography preview
   ============================================================ */

SELECT TOP 50
    GeographyKey,
    City,
    StateProvinceName,
    EnglishCountryRegionName AS country,
    PostalCode,
    SalesTerritoryKey
FROM dbo.DimGeography
ORDER BY country, StateProvinceName, City;