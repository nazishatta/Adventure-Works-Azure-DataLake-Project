/* ============================================================
   05 - Validation queries
   Depends on: 02_create_gold_views.sql, 04_create_gold_cetas.sql

   Run after a full deploy to confirm every gold object resolves.
   ============================================================ */

-- Row counts across all seven views
SELECT 'calendar'    AS gold_object, COUNT(*) AS row_count FROM gold.calendar
UNION ALL SELECT 'customers',    COUNT(*) FROM gold.customers
UNION ALL SELECT 'subcat',       COUNT(*) FROM gold.subcat
UNION ALL SELECT 'products',     COUNT(*) FROM gold.products
UNION ALL SELECT 'returns',      COUNT(*) FROM gold.returns
UNION ALL SELECT 'sales',        COUNT(*) FROM gold.sales
UNION ALL SELECT 'territories',  COUNT(*) FROM gold.territories
ORDER BY gold_object;
GO

-- Sample rows
SELECT TOP 100 * FROM gold.calendar;
GO

SELECT TOP 100 * FROM gold.customers;
GO

-- CETAS materialised table should match the gold.sales view
SELECT COUNT(*) AS cetas_rows FROM gold.extsales;
GO

SELECT COUNT(*) AS view_rows  FROM gold.sales;
GO
