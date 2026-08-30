# Adventure Works — Azure Data Lake Project

End-to-end Azure data engineering pipeline implementing a medallion architecture. AdventureWorks sales data is ingested from an HTTP source with Azure Data Factory, transformed with Databricks and PySpark, stored as Parquet across bronze / silver / gold layers on ADLS Gen2, and served through Azure Synapse Analytics serverless SQL.

---

## Architecture

```
HTTP source (GitHub raw)
        │
        ▼
Azure Data Factory ──────────► ADLS Gen2 : bronze   (raw CSV)
   Lookup → ForEach → Copy
        │
        ▼
Azure Databricks (PySpark) ──► ADLS Gen2 : silver   (cleaned Parquet)
        │
        ▼
Azure Synapse serverless SQL ► ADLS Gen2 : gold     (views + CETAS)
```

| Layer | Storage | Format | Built by |
|---|---|---|---|
| Bronze | `bronze` container | CSV, as ingested | Azure Data Factory |
| Silver | `silver` container | Parquet (Snappy) | Databricks / PySpark |
| Gold | Synapse `gold` schema | Views over silver Parquet, plus one CETAS table | Synapse serverless SQL |

---

## Stack

- **Azure Data Factory** — metadata-driven ingestion from HTTP into bronze
- **Azure Data Lake Storage Gen2** — hierarchical namespace enabled, LRS replication
- **Azure Databricks / PySpark** — bronze to silver transformation
- **Azure Synapse Analytics (serverless SQL)** — gold serving layer
- **GitHub** — source control for pipelines, notebooks, and SQL

---

## Repository layout

```
Data/                              Ten source CSVs, also the HTTP source for ADF

adf/
  config/git.json                  Ingestion manifest: URL, sink folder, filename
  linkedService/
    HttpLinkedService.json         raw.githubusercontent.com, anonymous auth
    StorageDataLake.json           ADLS Gen2
  dataset/
    ds_config_git.json             JSON dataset for the Lookup manifest
    ds_git_dynamic.json            Parameterised HTTP source (p_rel_url)
    ds_sink_dynamic.json           Parameterised bronze sink (p_sink_folder, p_file_name)
    ds_http.json                   Static source, single-file pipeline
    ds_raw.json                    Static sink, single-file pipeline
  pipeline/
    DynamicGitToRaw.json           Lookup → ForEach → parameterised Copy
    GitToRaw.json                  Earlier single-file version, kept for contrast
  factory/                         Factory configuration

databricks/notebooks/
  Silver_Layer.ipynb               Bronze to silver, with tables and charts rendered

synapse/
  01_create_schema.sql             Gold schema
  02_create_gold_views.sql         Seven views over silver Parquet
  03_create_external_objects.sql   Credential, data sources, file format
  04_create_gold_cetas.sql         CETAS materialising gold.sales
  05_validation_queries.sql        Row counts and spot checks

infrastructure/
  arm-template.json                Resource group ARM export
```

---

## Datasets

Ten AdventureWorks tables: Calendar, Customers, Product Categories, Product Subcategories, Products, Returns, Sales 2015, Sales 2016, Sales 2017, Territories.

The three yearly sales files are unified into a single `AdventureWorks_Sales` folder in the silver layer.

---

## Pipeline detail

### Ingestion — Azure Data Factory

Two pipelines are included deliberately.

**`GitToRaw`** copies a single hardcoded file. It works, but every new source file would need a new Copy activity and two new datasets.

**`DynamicGitToRaw`** is the version in use. `adf/config/git.json` holds one entry per file:

```json
{
    "p_rel_url": "nazishatta/Adventure-Works-Azure-DataLake-Project/main/Data/AdventureWorks_Calendar.csv",
    "p_sink_folder": "AdventureWorks_Calendar",
    "p_file_name": "AdventureWorks_Calendar.csv"
}
```

A Lookup reads the manifest with `firstRowOnly: false` so all ten entries are returned. A ForEach iterates `@activity('Lookupgit').output.value` with a batch count of 4, passing `@item().p_rel_url` to the source dataset and `@item().p_sink_folder` / `@item().p_file_name` to the sink. Adding a source file means adding a manifest entry — the pipeline itself does not change.

### Transformation — Databricks

Bronze CSVs are read with schema inference, transformed, and written to silver as Parquet:

- **Calendar** — derived `Month` and `Year` from `Date`
- **Customers** — `Full_Name` built with `concat_ws`, which tolerates null prefixes where `concat` would null the entire row
- **Products** — `ProductSKU` and `ProductName` split on their delimiters
- **Sales** — three yearly files unified, `StockDate` cast to timestamp, `ordernumber` normalised, `multiply` derived from line item and quantity
- **Returns, Territories, Product Subcategories** — passed through unchanged; no transformation required

The notebook renders 19 preview tables and three matplotlib charts (orders over time, products by category, orders by territory) inline.

### Serving — Synapse serverless SQL

Seven views read silver Parquet directly through `OPENROWSET`. These are zero-copy and always reflect current silver contents.

One CETAS (`gold.extsales`) materialises `gold.sales` as physical Parquet in the gold container, demonstrating the tradeoff: faster reads, but a snapshot that must be rebuilt, and physical files that must be cleaned up before the script can rerun.

Scripts are numbered by execution order and guarded with `DROP ... IF EXISTS` / `IF NOT EXISTS` so they are rerunnable.

---

## Engineering notes

**Authentication.** Databricks connects to ADLS Gen2 with a storage account access key. A service principal would be preferred, but app registration was blocked by the university Entra ID tenant. Synapse uses a Managed Identity through a database scoped credential, so no secret is stored in SQL. All credentials are redacted in this repository.

**A green Lookup proves nothing about the data.** During development every Copy activity failed while the Lookup succeeded. The Lookup only proved the manifest was readable, valid JSON — not that the values inside it were correct. Control-flow success and data-plane success are separate things.

**Raw GitHub URLs.** `raw.githubusercontent.com` routes from repository straight to branch. The `/blob/` segment that appears in browser URLs returns 404 and fails every Copy.

**CETAS is not idempotent.** `DROP EXTERNAL TABLE` removes SQL metadata but leaves the Parquet files in ADLS. Re-running the CETAS fails with "External table location already exists" until the folder is deleted. `04_create_gold_cetas.sql` documents the cleanup command.

**Views validate lazily.** `CREATE VIEW` in Synapse serverless does not check the underlying path. An invalid `BULK` location only surfaces on the first `SELECT` against the view.

**Region availability.** The Synapse workspace failed to provision in East US and East US 2 with `SqlServerRegionDoesNotAllowProvisioning`, and succeeded in Central US.

**Git integration is not optional.** Data Factory resources that exist only in live mode are not captured when a repository is connected — only published state is imported. The dynamic pipeline had to be rebuilt for this reason.

---

## Scope

**No reporting layer.** Power BI Desktop does not run on macOS, and the university tenant blocked content creation in the Power BI service, so the pipeline terminates at the Synapse gold layer. The gold views are queryable and would connect to any BI tool.

**Product Categories is not in silver.** The table is read in the notebook and used in the category chart join, but never written to silver, so no gold view exists for it. Seven of the ten source tables have gold views.

---

## Reproducing

1. Create an ADLS Gen2 storage account with hierarchical namespace enabled and `bronze`, `silver`, `gold` containers.
2. Deploy a Data Factory, connect it to this repository with root folder `/adf`, and update the linked services to point at your storage account.
3. Run `DynamicGitToRaw` to populate bronze.
4. Run `Silver_Layer.ipynb` in Databricks, substituting your own storage credential.
5. Run the Synapse scripts in numbered order against a serverless SQL pool, substituting your own master key password.
