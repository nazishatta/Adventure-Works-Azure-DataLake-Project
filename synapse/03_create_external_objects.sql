/* ============================================================
   03 - External objects for CETAS
   Depends on: 01_create_schema.sql

   Creates the master key, database scoped credential, external
   data sources, and Parquet file format required by the CETAS
   in 04.

   Order matters: the external table is dropped FIRST, because an
   external data source cannot be dropped while a table depends
   on it.

   SECURITY: replace the master key password placeholder below
   before running. Do not commit a real password.
   ============================================================ */

-- Drop dependent external table before touching source_gold
IF EXISTS (SELECT * FROM sys.external_tables
           WHERE name = 'extsales' AND schema_id = SCHEMA_ID('gold'))
    DROP EXTERNAL TABLE gold.extsales;
GO

-- Master key (encrypts the scoped credential)
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = '<MASTER_KEY_PASSWORD>';
GO

-- Scoped credential using the workspace Managed Identity.
-- MI is used rather than a storage key so no secret lives in SQL.
IF NOT EXISTS (SELECT * FROM sys.database_scoped_credentials WHERE name = 'cred_nazi')
    CREATE DATABASE SCOPED CREDENTIAL cred_nazi
    WITH IDENTITY = 'Managed Identity';
GO

-- Silver data source
IF EXISTS (SELECT * FROM sys.external_data_sources WHERE name = 'source_silver')
    DROP EXTERNAL DATA SOURCE source_silver;
GO
CREATE EXTERNAL DATA SOURCE source_silver
WITH (
    LOCATION   = 'abfss://silver@storagedatalakenazi.dfs.core.windows.net',
    CREDENTIAL = cred_nazi
);
GO

-- Gold data source
IF EXISTS (SELECT * FROM sys.external_data_sources WHERE name = 'source_gold')
    DROP EXTERNAL DATA SOURCE source_gold;
GO
CREATE EXTERNAL DATA SOURCE source_gold
WITH (
    LOCATION   = 'abfss://gold@storagedatalakenazi.dfs.core.windows.net',
    CREDENTIAL = cred_nazi
);
GO

-- Parquet file format with Snappy compression
IF EXISTS (SELECT * FROM sys.external_file_formats WHERE name = 'format_parquet')
    DROP EXTERNAL FILE FORMAT format_parquet;
GO
CREATE EXTERNAL FILE FORMAT format_parquet
WITH (
    FORMAT_TYPE      = PARQUET,
    DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec'
);
GO
