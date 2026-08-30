/* ============================================================
   02 - Gold layer views over Silver Parquet
   Depends on: 01_create_schema.sql

   Views read Silver Parquet directly via OPENROWSET. They are
   lightweight (no data movement) and always reflect the current
   contents of the Silver layer.

   Each view is dropped before creation so the script is rerunnable.
   Note: CREATE VIEW does not validate the underlying path -- an
   invalid BULK location only surfaces on the first SELECT.
   ============================================================ */

------------------------------------------------------------
-- Calendar
------------------------------------------------------------
DROP VIEW IF EXISTS gold.calendar;
GO
CREATE VIEW gold.calendar AS
SELECT *
FROM OPENROWSET(
    BULK 'abfss://silver@storagedatalakenazi.dfs.core.windows.net/AdventureWorks_Calendar/',
    FORMAT = 'PARQUET'
) AS q;
GO

------------------------------------------------------------
-- Customers
------------------------------------------------------------
DROP VIEW IF EXISTS gold.customers;
GO
CREATE VIEW gold.customers AS
SELECT *
FROM OPENROWSET(
    BULK 'abfss://silver@storagedatalakenazi.dfs.core.windows.net/AdventureWorks_Customers/',
    FORMAT = 'PARQUET'
) AS q;
GO

------------------------------------------------------------
-- Product subcategories
------------------------------------------------------------
DROP VIEW IF EXISTS gold.subcat;
GO
CREATE VIEW gold.subcat AS
SELECT *
FROM OPENROWSET(
    BULK 'abfss://silver@storagedatalakenazi.dfs.core.windows.net/AdventureWorks_Product_Subcategories/',
    FORMAT = 'PARQUET'
) AS q;
GO

------------------------------------------------------------
-- Products
------------------------------------------------------------
DROP VIEW IF EXISTS gold.products;
GO
CREATE VIEW gold.products AS
SELECT *
FROM OPENROWSET(
    BULK 'abfss://silver@storagedatalakenazi.dfs.core.windows.net/AdventureWorks_Products/',
    FORMAT = 'PARQUET'
) AS q;
GO

------------------------------------------------------------
-- Returns
------------------------------------------------------------
DROP VIEW IF EXISTS gold.returns;
GO
CREATE VIEW gold.returns AS
SELECT *
FROM OPENROWSET(
    BULK 'abfss://silver@storagedatalakenazi.dfs.core.windows.net/AdventureWorks_Returns/',
    FORMAT = 'PARQUET'
) AS q;
GO

------------------------------------------------------------
-- Sales (all three years unified in the Silver layer)
------------------------------------------------------------
DROP VIEW IF EXISTS gold.sales;
GO
CREATE VIEW gold.sales AS
SELECT *
FROM OPENROWSET(
    BULK 'abfss://silver@storagedatalakenazi.dfs.core.windows.net/AdventureWorks_Sales/',
    FORMAT = 'PARQUET'
) AS q;
GO

------------------------------------------------------------
-- Territories
------------------------------------------------------------
DROP VIEW IF EXISTS gold.territories;
GO
CREATE VIEW gold.territories AS
SELECT *
FROM OPENROWSET(
    BULK 'abfss://silver@storagedatalakenazi.dfs.core.windows.net/AdventureWorks_Territories/',
    FORMAT = 'PARQUET'
) AS q;
GO
