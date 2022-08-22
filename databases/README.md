# Database deployment

This solution contains the code to reliably and idempotently deploy database tables, views, stored procedures, views, functions and data into one or more Azure SQL Databases.

It contains the following components:

- [**Deployment scripts**](#Deployment-scripts) - The necessary files to orchestrate the deployment using Azure DevOps
- [**Migrator**](#Migrator) - A C# application using [DbUp](http://dbup.github.io/) that allows you to deploy a folder (based on a [file/folder convention](#Filefolder-convention)) to a database (via a connection string)
- [**ADP_Config**](#ADP_Config) - The definition of the Azure Data Platform Config database (using the aforementioned file/folder convention)
- [**ADP_Stage**](#ADP_Stage) - The definition of the Azure Data Platform Stage database (using the aforementioned file/folder convention)

# Deployment scripts

The deployment scripts contain the following files:

- `azure-pipelines.yml` - The Azure DevOps deployment pipeline; this orchestrates the build of the database solution (including copying infrastructure and database definition folders and building the migrator app) as well as the deployment via the `deployment-steps.yml` file
- `deployment-steps.yml` - This takes the artifacts from the build and passes in relevant parameters to the `deployment.ps1` file so it can successfully execute against the passed in environment
- `deployment.ps1` - This orchestrates the actual deployment of the databases by:
  1. Getting the required config information from the [infrastructure deployment](../infrastructure/README.md) e.g. database server name, sql admin credentials, database names, etc.
  2. Temporarily grant access to the SQL Server firewall for the current IP address
  3. Apply the database configuration to the `ADP_Config` database
  4. Apply the database configuration to the `ADP_Stage` database
  5. Remove temporary firewall access (this happens regardless of whether there are exceptions with applying the configuration)
  6. Return a non-zero exit code if there are any errors or a `0` exit code if it was successful

# Migrator

This is a C# .NET Core 3.1 Console application that uses [DbUp](http://dbup.github.io/) to apply the database configuration. In order to run this you will need to have [.NET SDK](https://dotnet.microsoft.com/download) installed on your computer.

## Running locally / debugging

Running the console app directly will apply the configuration for `ADP_Config` and `ADP_Stage` to the local SQL Express instance (`.\sqlexpress`), which must be present, available for the executing user to connect using their Windows credentials with admin privileges (the default setup) and be at least SQL Server 2019 for it to succeed.

If you are on Windows and you have [Chocolatey](https://chocolatey.org/) you can execute the following to get such an instance setup:

> `choco install -y sql-server-express`

### Using VS Code

If you open this repository in VS Code and change your [launch configuration](https://code.visualstudio.com/Docs/editor/debugging) by opening the Run menu (Ctrl+Shift+D on windows) and selecting the `Database.Migrator (build and run/debug locally)` launch configuration. Then simply hit the `Start debugging` button or `F5`. It will automatically build the C# project and then run the console app with debugger attached for you.

## Running non-locally

There is a `Migrator` static class defined in `Migrator.cs` that can be called directly to apply a database configuration. The signature looks like this:

```c#
namespace Migrator
{
    /// <summary>
    /// The result of executing a database migration
    /// </summary>
    public class MigratorResult
    {
        /// <summary>
        /// If the migration was successful
        /// </summary>
        public bool IsSuccessful { get; set; }
        /// <summary>
        /// If it wasn't successful then the error that was received.
        /// </summary>
        public string Errors { get; set; }
    }

    /// <summary>
    /// Orchestrates database migrations from the filesystem via a folder/file convention.
    /// </summary>
    public static class Migrator
    {
        /// <summary>
        /// Migrates a folder into a SQL Connection - separating:
        ///  * Migrations (which are journaled so they run once only)
        ///  * Functions
        ///  * Procedures; and
        ///  * Views
        ///
        /// The first is based on executing each file in alphabetical order and using the file name as a persistent journal identifier.
        /// The latter 3 are based on a folder convention with the same name and one file per item.
        /// </summary>
        /// <param name="rootFolder">The root folder with the various convention sub folders</param>
        /// <param name="connection">An open SQL connection to the database to migrate as an identity with DDL permissions</param>
        /// <returns>The result</returns>
        public static MigratorResult Migrate(string rootFolder, string connectionString) {...}
    }
}
```

To apply a configuration you simply import the DLL and call:

```c#
Migrator.Migrator.Migrate("path/to/database/root/folder", "Server=sqlConnectionString;...")
```

To call it from PowerShell you can use:

```powershell
Add-Type -Path (Join-Path $MigratorLocation "Migrator.dll")
[Migrator.Migrator]::Migrate($databaseRootFolder, $connectionString)
```

### Using VS Code

If you open this repository in VS Code and change your [launch configuration](https://code.visualstudio.com/Docs/editor/debugging) by opening the Run menu (Ctrl+Shift+D on windows) and selecting the `Database.Deployment` launch configuration. Then simply hit the `Start debugging` button or `F5`. It will run the `deployment.ps1` file with the right parameters to execute against your [locally deployed infrastructure](../infrastructure/README.md) with the debugger attached for you.

## File/folder convention

The migrator script uses the following file/folder convention when applying a database configuration:

- `Functions` - Any user-defined functions:
  - One file per function with file name `{schema}.{functionName}.UserDefinedFunction.sql`
  - Start with a `DROP FUNCTION IF EXISTS` statement before the `CREATE FUNCTION` statement so that it's idempotent
  - These scripts will be **run every time** the config is applied
- `Migrations` - Any schema [migrations](https://dbup.readthedocs.io/en/latest/philosophy-behind-dbup/):
  - One file per migration (schema change) with file name `{YYYY-MM-DDTHHMM}-{BriefDescriptionOfChange}.sql` - where the date is the date the migration file is created
  - Include the delta from the current state (assuming all previous migration scripts have been run once in sequential order) i.e. if the table doesn't exist it's a `CREATE TABLE`, if it does exist it's an `ALTER TABLE`, if you are adding new seed data it's an `INSERT`, if you are modifying data it's an `UPDATE` etc.
  - These scripts will be **once only per database instance** - DbUp has a journal table where it keeps track of which migrations have successfully been applied
  - The series of migrations to apply will be wrapped in a transaction, which will get rolled back if any migration fails in that batch
  - These files will never be modified after they have reached the Main branch - they must be immutable; once something reaches Main if you need to change it then you need to write a new migration
  - Don't assume the database name or anything else that may vary across environments; the script needs to successfully run on every environment / instance
- `Procedures` - Any stored procedures:
  - One file per procedure with file name `{schema}.{procedureName}.StoredProcedure.sql`
  - Start with:
    ```sql
    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[{schema}].[{procedureName}]') AND type in (N'P', N'PC')) BEGIN EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [{schema}].[{procedureName}] AS' END GO
    ```
  - Then after that make the declaration an `ALTER PROCEDURE` statement so that it's idempotent
  - These scripts will be **run every time** the config is applied
- `Views` - Any views:
  - One file per function with file name `{schema}.{viewName}.View.sql`
  - Start with a `DROP VIEW IF EXISTS` statement before the `CREATE VIEW` statement so that it's idempotent
  - These scripts will be **run every time** the config is applied

Any folders that aren't present will be skipped gracefully.

# ADP_Config

The Azure Data Platform definition for the Config database is in the `ADP_Config` folder.

# ADP_Stage

The Azure Data Platform definition for the Stage database is in the `ADP_Stage` folder.
