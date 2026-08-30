/* ============================================================
   01 - Gold schema
   Run first. Everything else depends on this schema existing.
   ============================================================ */

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gold')
    EXEC('CREATE SCHEMA gold');
GO
