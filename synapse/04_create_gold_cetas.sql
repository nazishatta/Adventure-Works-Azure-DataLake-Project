/* ============================================================
   04 - CETAS: materialise gold.sales as Parquet
   Depends on: 02_create_gold_views.sql, 03_create_external_objects.sql

   CETAS (CREATE EXTERNAL TABLE AS SELECT) writes query results to
   physical Parquet files in the gold container. Unlike a view, the
   data is materialised -- faster to query, but it is a snapshot and
   must be rebuilt when Silver changes.

   ---------------------------------------------------------------
   RERUN REQUIREMENT
   ---------------------------------------------------------------
   DROP EXTERNAL TABLE removes only the SQL metadata. The Parquet
   files stay in ADLS. Re-running this script against the same
   LOCATION fails with:

       "Cannot create external table. External table location
        already exists."

   Before re-running, delete the target folder from the gold
   container (Storage Explorer or Azure CLI):

       az storage fs directory delete \
         --file-system gold \
         --name extsales \
         --account-name storagedatalakenazi

   This is why serverless CETAS is not idempotent on its own, and
   why production pipelines normally orchestrate the cleanup step.
   ============================================================ */

IF EXISTS (SELECT * FROM sys.external_tables
           WHERE name = 'extsales' AND schema_id = SCHEMA_ID('gold'))
    DROP EXTERNAL TABLE gold.extsales;
GO

CREATE EXTERNAL TABLE gold.extsales
WITH (
    LOCATION    = 'extsales',
    DATA_SOURCE = source_gold,
    FILE_FORMAT = format_parquet
)
AS
SELECT * FROM gold.sales;
GO
