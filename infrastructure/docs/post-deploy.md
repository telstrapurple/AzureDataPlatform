# Post-deployment steps

[[_TOC_]]

There are some post-deployment manual steps that need to be performed once only the first time a deployment is performed:

1. Go to the admin resource group, show hidden items and go to both of the web connections (automation and office365) and authorise them.
1. Configure the KeyVault back Databricks backed secret scope. See [KeyVault backed Databricks scope and Service Principals](#KeyVault-backed-Databricks-scope-and-Service-Principals) below.
1. Follow the [steps to configure the WebApp solution](#configure-the-solution-to-ingest-and-transform-data) for ingestion.
1. Configure the Purview Integreation run time by following the [Deploy Azure Purview Runtime Integration](#Deploy-Azure-Purview-Runtime-Integration).
1. Configure the PowerBI Gateway if the PowerBI virtual machines are deployed.

## Configure the solution to ingest and transform data

- Go into the Configurator web app and capture the following:
  - **Systems** for all of the new data sources. Use the **System Code** as the name of the target schema in the landing database
  - **Connections** for all of the new data sources. Capture the **KeyVault secret** connection property relevant to each source system
- Import the provided csv file with all the required tables and schemas into the **SRC.DatabaseTable** table in the ADS_Config database
  - If required , modify the **[DI].[usp_InitialDatabaseSystemTask_Insert]** and **[DI].[usp_StagingTableScript_Generate]** stored procedures in the **ADP_Config** database to make provision for specific object naming conventions. Run the [DI].[usp_InitialDatabaseSystemTask_Insert] stored procedure to insert the initial list of systems and tasks.

## Deploy Azure Purview Runtime Integration

The Pipeline can deploy the Azure Purview Account and Virtual Machines, however the Integration Key is needed for the Virtual Machine installation. Follow the [Azure Purview](https://docs.microsoft.com/en-us/azure/purview/manage-integration-runtimes#create-a-self-hosted-integration-runtime) documentation to create the Runtime and add the Integration Key to the Deployment KeyVault using the secret name `purviewIntegrationKey`.
