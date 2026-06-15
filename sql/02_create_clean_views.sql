/* 
Project: Sales Channel Performance Analytics Dashboard
Dataset: AdventureWorksDW2022
File: 02_create_clean_views.sql

Purpose:
Create cleaned SQL views for Power BI reporting later.
The views simplify table names, standardize column names, clean missing values,
combine sales channels, and prepare a star-schema style model for dashboarding.
*/

USE AdventureWorksDW2022;
GO


/* ============================================================
   1. Date dimension view
   ============================================================ */

CREATE OR ALTER VIEW dbo.vw_dim_date AS
SELECT
    DateKey AS date_key,
    FullDateAlternateKey AS full_date,
    CalendarYear AS calendar_year,
    CalendarQuarter AS calendar_quarter,
    MonthNumberOfYear AS month_number,
    EnglishMonthName AS month_name,
    LEFT(EnglishMonthName, 3) AS month_short_name,
    WeekNumberOfYear AS week_number,
    DayNumberOfMonth AS day_number_of_month,
    EnglishDayNameOfWeek AS day_name,
    FiscalYear AS fiscal_year,
    FiscalQuarter AS fiscal_quarter,
    FiscalSemester AS fiscal_semester
FROM dbo.DimDate;
GO


/* ============================================================
   2. Product dimension view
   ============================================================ */

CREATE OR ALTER VIEW dbo.vw_dim_product AS
SELECT
    p.ProductKey AS product_key,
    p.ProductAlternateKey AS product_alternate_key,
    p.EnglishProductName AS product_name,

    COALESCE(ps.EnglishProductSubcategoryName, 'Unknown') AS product_subcategory,
    COALESCE(pc.EnglishProductCategoryName, 'Unknown') AS product_category,

    COALESCE(p.Color, 'Unknown') AS color,
    COALESCE(p.Size, 'Unknown') AS size,
    COALESCE(p.SizeRange, 'Unknown') AS size_range,

    COALESCE(p.ProductLine, 'Unknown') AS product_line,
    COALESCE(p.Class, 'Unknown') AS product_class,
    COALESCE(p.Style, 'Unknown') AS product_style,

    p.StandardCost AS standard_cost,
    p.ListPrice AS list_price,
    p.DealerPrice AS dealer_price,

    p.StartDate AS product_start_date,
    p.EndDate AS product_end_date,
    COALESCE(p.Status, 'Unknown') AS product_status
FROM dbo.DimProduct p
LEFT JOIN dbo.DimProductSubcategory ps
    ON p.ProductSubcategoryKey = ps.ProductSubcategoryKey
LEFT JOIN dbo.DimProductCategory pc
    ON ps.ProductCategoryKey = pc.ProductCategoryKey;
GO


/* ============================================================
   3. Customer dimension view
   ============================================================ */

CREATE OR ALTER VIEW dbo.vw_dim_customer AS
SELECT
    c.CustomerKey AS customer_key,
    c.CustomerAlternateKey AS customer_alternate_key,

    CONCAT(
        COALESCE(c.FirstName, ''),
        ' ',
        COALESCE(c.LastName, '')
    ) AS customer_name,

    CASE 
        WHEN c.Gender = 'M' THEN 'Male'
        WHEN c.Gender = 'F' THEN 'Female'
        ELSE 'Unknown'
    END AS gender,

    CASE
        WHEN c.MaritalStatus = 'M' THEN 'Married'
        WHEN c.MaritalStatus = 'S' THEN 'Single'
        ELSE 'Unknown'
    END AS marital_status,

    c.BirthDate AS birth_date,
    c.YearlyIncome AS yearly_income,

    CASE
        WHEN c.YearlyIncome < 40000 THEN 'Low Income'
        WHEN c.YearlyIncome < 80000 THEN 'Middle Income'
        WHEN c.YearlyIncome >= 80000 THEN 'High Income'
        ELSE 'Unknown'
    END AS income_group,

    c.TotalChildren AS total_children,
    c.NumberChildrenAtHome AS children_at_home,
    c.EnglishEducation AS education,
    c.EnglishOccupation AS occupation,
    c.HouseOwnerFlag AS house_owner_flag,
    c.NumberCarsOwned AS number_cars_owned,
    c.CommuteDistance AS commute_distance,
    c.DateFirstPurchase AS date_first_purchase,

    g.City AS city,
    g.StateProvinceName AS state_province,
    g.EnglishCountryRegionName AS country,
    g.SalesTerritoryKey AS sales_territory_key
FROM dbo.DimCustomer c
LEFT JOIN dbo.DimGeography g
    ON c.GeographyKey = g.GeographyKey;
GO


/* ============================================================
   4. Sales territory dimension view
   ============================================================ */

CREATE OR ALTER VIEW dbo.vw_dim_sales_territory AS
SELECT
    SalesTerritoryKey AS sales_territory_key,
    SalesTerritoryRegion AS sales_territory_region,
    SalesTerritoryCountry AS sales_territory_country,
    SalesTerritoryGroup AS sales_territory_group
FROM dbo.DimSalesTerritory;
GO


/* ============================================================
   5. Combined sales fact view
   ============================================================ */

CREATE OR ALTER VIEW dbo.vw_fact_sales AS

SELECT
    'Internet Sales' AS sales_channel,

    SalesOrderNumber AS sales_order_number,
    SalesOrderLineNumber AS sales_order_line_number,

    OrderDateKey AS order_date_key,
    DueDateKey AS due_date_key,
    ShipDateKey AS ship_date_key,

    OrderDate AS order_date,
    DueDate AS due_date,
    ShipDate AS ship_date,

    ProductKey AS product_key,
    CustomerKey AS customer_key,
    CAST(NULL AS INT) AS reseller_key,
    SalesTerritoryKey AS sales_territory_key,

    OrderQuantity AS order_quantity,
    UnitPrice AS unit_price,
    ExtendedAmount AS extended_amount,
    DiscountAmount AS discount_amount,
    ProductStandardCost AS product_standard_cost,
    TotalProductCost AS total_product_cost,
    SalesAmount AS sales_amount,
    TaxAmt AS tax_amount,
    Freight AS freight,

    SalesAmount - TotalProductCost AS gross_profit

FROM dbo.FactInternetSales

UNION ALL

SELECT
    'Reseller Sales' AS sales_channel,

    SalesOrderNumber AS sales_order_number,
    SalesOrderLineNumber AS sales_order_line_number,

    OrderDateKey AS order_date_key,
    DueDateKey AS due_date_key,
    ShipDateKey AS ship_date_key,

    OrderDate AS order_date,
    DueDate AS due_date,
    ShipDate AS ship_date,

    ProductKey AS product_key,
    CAST(NULL AS INT) AS customer_key,
    ResellerKey AS reseller_key,
    SalesTerritoryKey AS sales_territory_key,

    OrderQuantity AS order_quantity,
    UnitPrice AS unit_price,
    ExtendedAmount AS extended_amount,
    DiscountAmount AS discount_amount,
    ProductStandardCost AS product_standard_cost,
    TotalProductCost AS total_product_cost,
    SalesAmount AS sales_amount,
    TaxAmt AS tax_amount,
    Freight AS freight,

    SalesAmount - TotalProductCost AS gross_profit

FROM dbo.FactResellerSales;
GO


/* ============================================================
   6. Validate created views
   ============================================================ */

SELECT 'vw_dim_date' AS view_name, COUNT(*) AS row_count
FROM dbo.vw_dim_date

UNION ALL

SELECT 'vw_dim_product', COUNT(*)
FROM dbo.vw_dim_product

UNION ALL

SELECT 'vw_dim_customer', COUNT(*)
FROM dbo.vw_dim_customer

UNION ALL

SELECT 'vw_dim_sales_territory', COUNT(*)
FROM dbo.vw_dim_sales_territory

UNION ALL

SELECT 'vw_fact_sales', COUNT(*)
FROM dbo.vw_fact_sales;
GO


/* ============================================================
   7. Preview combined sales view
   ============================================================ */

SELECT TOP 20
    sales_channel,
    sales_order_number,
    order_date,
    product_key,
    customer_key,
    reseller_key,
    sales_territory_key,
    order_quantity,
    sales_amount,
    total_product_cost,
    gross_profit
FROM dbo.vw_fact_sales
ORDER BY order_date;
GO