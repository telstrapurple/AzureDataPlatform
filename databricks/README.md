# Azure Databricks

## Naming Standards

### Folders (Workspaces)

Follow the same naming conventions as the data lake subject areas i.e. Subject area on the highest level and then source.

### Notebooks

All notebook names should be descriptive and indicate the Subject Area which is being affected by the contained scripts.
Notebooks will be split by frequency and source, but this can revised on a case by case basis.

### Databases

Short lived processes (ETL related workloads) will not persists their data in a Databricks database. For any data that is required for additional analytics workloads, all tables will be placed in the Sandbox database. Table naming conventions will define what the data in the tables relates to. Data that needs to persist should be stored in a database named after the data source.

### Tables

Create a logical grouping of tables based on the data source e.g. SES. This will be prefixed onto the table name to simplify the process of locating all tables relating to a specific data source.

### Clusters

The naming convention below will be used for all clusters

Naming Convention: `<CompanyCode><delimiter><LocationCode><delimiter><Environment><delimiter><PlatformName><delimiter><ResourceType><delimiter><Count><delimiter>CLU<delimiter><Mode/Descriptor>`

For example

- TP-SYD-DEV-ADP-DBR-001-CLU-Standard,
- TP-SYD-DEV-ADP-DBR-001-CLU-HighConcurrency, or
- TP-SYD-DEV-ADP-DBR-001-CLU-FreeText

**Jobs**
TBD – To be decided when / if jobs are used
