# Web application

## Get started

### Database Setup

1. Set up a SQL express server
1. Open the repository in Visual Studio Code.
1. Click on the Run and Debug menu on the right hand side.
1. In the Run and Debug drop down menu select `Database.Migrator (build and run locally)
1. If it doesn't work, check that your SQL express server has the same name as is assumed in [this connection string](databases\Migrator\Program.cs:28)

### Config file

To get started quickly, a template settings file is provided for development.
In the `ADPConfigurator/Web` directory, make a copy of the `appsettings.Development.template.json` and save it as `appsettings.Development.json`.

Do the same for `ADPConfigurator/Api`.

You can make changes to it if needed as it's ignored by Git.
By default, it assumes you're connecting to the SQL database on a LocalDB instance, but use whatever floats your boat.

### Run the app

At this stage, you should be able to `F5` the solution.

### Optionally make you an admin

The first time you log in to the app, a record is created in the `[DI].[User]` table.
However, you can't access all the management pages if you're not an admin.

You can run the following SQL query to bump your user to being an admin:

```sql
UPDATE
    [DI].[USER]
SET
    [AdminIndicator] = 1
WHERE
    [EmailAddress] = '<email-address-of-the-account-you-use>'
```
