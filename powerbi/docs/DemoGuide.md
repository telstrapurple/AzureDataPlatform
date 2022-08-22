# Demo Guide
This guide aims to document the steps you would need to perform to set up a working demo for Agile Enterprise BI. 

Motivation: 
- You may need a demo to showcase the framework's features to a Client
- You may need a demo to train others on how the framework operates
- You may be skilling-up on the framework before delivering to a Client 

These are all good reasons why you may need a demo. The rest of this guide explains how to set one up.

## Table of Contents
| Step | Title | Notes |
|---|---|---|
|01| [Azure DevOps Setup](#01-azure-devops-setup) | - | 
|02| [Creating an Azure Tenant](#02-creating-an-azure-tenant) | - |
|03| [Importing WideWorldImporters DB and DW](#03-importing-wideworldimporters-db-and-dw) | - |
|04| [Creating Azure AD Users and Groups](#04-creating-azure-ad-users-and-groups) | - |
|05| [Creating Power BI Workspaces](#05-creating-power-bi-workspaces) | - |
|06| [Provision SQL Server access to users](#06-provision-sql-server-access-to-users) | - |
|07| [Deploying Power BI Content](#07-deploying-power-bi-content) | - |

# 01 Azure DevOps Setup
For the demo, you will be creating a new Azure DevOps Repo. Refer to the guide here if required: https://docs.microsoft.com/en-us/azure/devops/repos/git/create-new-repo?view=azure-devops

Download this existing repo into your local directory and un-zip the file. Perform a Git Push to the remote repo. 

# 02 Creating an Azure Tenant
For the demo, you will require Power BI Admin privelleges and Azure AD admin privelleges. In most cases, Telstra Purple would not grant us (consultants) such access. Therefore, you will need to create a demo Tenant. To do so, follow this guide here: https://docs.microsoft.com/en-us/power-bi/developer/embedded/create-an-azure-active-directory-tenant

We shall use this Tenant **only** for the following situations: 
- Creating demo Azure AD Users
- Creating demo Azure AD Groups
- Creating demo Power BI Workspaces 

For all other situations e.g. deploying a SQL Server, please use your MSDN subscription or an authorized Telstra Purple demo subscription. 

# 03 Importing WideWorldImporters DB and DW
WideWorldImporters is a fictional wholesaler business. For the demo, you will require: 
- WideWorldImporters DB - The DB shall be used to represent the Staging Layer
- WideWorldImporters DW - The DW shall be used to represent the Transformed Layer

To get copies of the databases, head to the following URL: https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
- Download `WideWorldImporters-Standard.bacpac` 
- Download `WideWorldImportersDW-Standard.bacpac`

For documentation around the Database schemas, refer to: https://docs.microsoft.com/en-us/sql/samples/wide-world-importers-what-is?view=sql-server-ver15

After downloading the `.bacpac` files, deploy an Azure SQL Server in your MSDN or Telstra Purple demo subscription. Import the .bacpac to the SQL Server using SQL Server Management Studio (SSMS). Provide the following names for the Databases: 
- WideWorldImporters-DB
- WideWorldImporters-DW

For the datbase tier, we recommend using the Standard Tier (S1) with 30 GB of data. That should provide sufficient storage and performance for the demo. You may also wish to use a higher Tier during the Import process so that the importation takes less time (it will take up to 20 mins to import on the S1 tier). You can change the Tier back to S1 later on via the Azure Portal. 

# 04 Creating Azure AD Users and Groups
Access the [demo mapping Excel Workbook]() and Export the mappings to CSV. Execute the following PowerShell scripts against the relevant CSV files: 
- [New-AzureADUsersFromCsv.ps1](..\powershell\administration\azureAD\New-AzureADUsersFromCsv.ps1) - Creates demo Azure AD Users
- [New-AzureADGroupsFromCsv.ps1](..\powershell\administration\azureAD\New-AzureADGroupsFromCsv.ps1) - Creates demo Azure AD Groups
- [Add-AzureADGroupUsersFromCsv.ps1](..\powershell\administration\azureAD\Add-AzureADGroupUsersFromCsv.ps1) - Adds demo AAD Users to demo AAD Groups

# 05 Creating Power BI Workspaces
Access the [demo mapping Excel Workbook]() and Export the mappings to CSV. Execute the following PowerShell scripts against the relevant CSV files: 
- [New-PowerBIWorkspacesFromCsv.ps1](..\powershell\administration\powerbi\New-PowerBIWorkspacesFromCsv.ps1) - Creates demo Power BI Workspaces (dev, UAT, production)
- [Add-PowerBIUsersFromCsv.ps1](..\powershell\administration\powerbi\Add-PowerBIUsersFromCsv.ps1) - Adds Azure AD Groups (contributors) to Power BI 'Team' Workspaces
- You will need to provision access manually for Azure AD Groups to Power BI App (unfortunately there is no Power BI REST API for this task)

# 06 Provision SQL Server access to users
In the real world, you would avoid granting access to a SQL Server directly to individual users. Instead you would do so using AAD Groups. 
However, to make our lives easier for the demo, we shall provision access using the following mappings:
| Database | Schema | User | 
|---|---|---|
| WideWorldImporters-DB | *All* | biTeam |
| WideWorldImporters-DB | Sales | salesBIContributor |
| WideWorldImporters-DW | *All* | biTeam |
| WideWorldImporters-DW | Dimension | salesBIContributor |
| WideWorldImporters-DW | Fact | salesBIContributor |

Execute the following scripts which will provision the required access based on the table above:  
#### Execute on 'master' database: 
```sql
CREATE LOGIN biTeam WITH PASSWORD = '<passwordHere>' -- Creates login for biTeam user in master database
CREATE LOGIN salesBIContributor WITH PASSWORD = '<passwordHere>' -- Creates login for salesBIContributor user in master database
```
#### Execute on 'WideWorldImporters-DB' database: 
```sql
CREATE USER biTeam -- creates biTeam user in DB
ALTER ROLE db_owner ADD MEMBER biTeam -- adds biTeam user to the db_owner role

CREATE USER salesBIContributor -- creates salesBIContributor user in DB
GRANT SELECT ON SCHEMA :: Sales TO salesBIContributor WITH GRANT OPTION;  -- grants salesBIContributor the ability to SELECT from Sales schema
```
#### Execute on 'WideWorldImporters-DW' database: 
```sql
CREATE USER biTeam -- creates biTeam user in DB
ALTER ROLE db_owner ADD MEMBER biTeam -- adds biTeam user to the db_owner role

CREATE USER salesBIContributor -- creates salesBIContributor user in DB
GRANT SELECT ON SCHEMA :: Dimension TO salesBIContributor WITH GRANT OPTION;  -- grants salesBIContributor the ability to SELECT from Dimension schema
GRANT SELECT ON SCHEMA :: Fact TO salesBIContributor WITH GRANT OPTION; -- grants salesBIContributor the ability to SELECT from Fact schema
```

# 07 Deploying Power BI Content
Access the [Power BI demo content]() and update the PowerQuery connection string to your deployed Azure SQL Databases. 

For authentication, please use the table below as a reference for what authentication to use for eact report. This is required because some reports are self-service whereas the others aren't, and self-service users would use a different credential as compared to a Corporate BI developer.

| Power BI Report Name | Azure AD User |
|---|---|
| TBC | TBC | 

## Self-Service Deployment
For self-service deployment, simply manually publish the following Power BI Reports to the workspaces listed in the table below. 
| Power BI Report Name | Workspace Name |
|---|---|
| TBC | TBC | 

## Corporate BI Deployment
Start by configuring CI/CD pipelines, directory and config files using the [Corproate BI CI/CD Guide](corporate-bi-cicd-guide.md). 

After the pipeline is configured, update the `config.json` file for the reports below with the appropriate WorkspaceId.
| Power BI Report Name | Workspace Name |
|---|---|
| TBC | TBC | 

After the `config.json` is updated, simply create a pull request to bring your changes to the `master` branch. The CI/CD pipeline will automatically trigger upon changes to the `/powerbi` folder and deploy your changes. You will receive a notification to perform approval for Production, but not for UAT. This is by design as we want changes to be quickly deployed to UAT without the need for an approval to speed up the process since changes has already been reviewed and approved in the PR phase. 

