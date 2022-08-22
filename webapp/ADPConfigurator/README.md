# Azure Data Platform Configurator

Web application to view and manage data management automation tasks performed within various systems.

## Running locally

1. Decide to use either a local SQL Server instance or a cloud-hosted instance, set it up if necessary, and get the connection details

   - For an Azure-hosted database, you may need to add a firewall rule exception (note this is an SQL Server setting, not an SQL Database setting)
   - For a new instance, you may need to add seed data to it, copied from another database

1. Get the Azure AD details - domain name, tenant ID and application registration ID

1. Copy `appsettings.Development.template.json` in the `Web` project to another file named `appsettings.Development.json` (note the case) (this file is excluded from version control)

   - Note that this expects that the `ASPNETCORE_ENVIRONMENT` environment variable is set to `Development`; when using Rider IDE this must be added to the run configuration

1. In that new file, replace the following tokens with the correct values:

   - `AzureAd.Domain`: the Azure AD domain name (e.g. `purple.telstra.com`)
   - `AzureAd.TenantId`: the Azure AD tenant identifier (a UUID, corresponds to the Azure AD tenancy)
   - `AzureAd.ClientId`: the Azure AD client application registration identifier (another UUID, specific to this application - you generally don't need to change this, the default client id set in `appsettings.Development.template.json` is already configured with the right permissions and the localhost redirect URLs)
   - `ApplicationConfig.ConnectionString`: the database's ODBC connection string, it's set to the local database that the migrator project deploys to by default

1. The application runs as a standard `dotnet` web application - you can build the solution and run the `Web` project without arguments, and it will start a web server listening to HTTP on port `5000` and HTTPS on port `5001`

1. Navigate to <https://localhost:44399/> to see your running application (you will need to allow the certificate mismatch exception).

## Managing models

The application domain model is database-first: make the required changes to the database structure (via the migrator project), and then update the models:

1. Install the Entity Framework tools:

   ```
   dotnet tool install --global dotnet-ef
   ```

1. In the `Domain` project directory, run the scaffolding tool:

   ```
   dotnet ef dbcontext scaffold "<CONNECTION_STRING>" Microsoft.EntityFrameworkCore.SqlServer -o Models --force
   ```

   Or if you are using PowerShell, you can use the equivalent:

   ```
   Scaffold-DbContext "<CONNECTION_STRING>" Microsoft.EntityFrameworkCore.SqlServer -OutputDir Models -Force
   ```

   - The connection string is the same you use to configure your application
   - More details [in the documentation](https://docs.microsoft.com/en-us/ef/core/miscellaneous/cli/dotnet)

1. Add back the following block of code in ADS_ConfigContext.cs (the scaffolding tool will overwrite it):

   ```
   public ADS_ConfigContext(DbContextOptions<ADS_ConfigContext> options)
            : base(options)
   {
      var conn = (Microsoft.Data.SqlClient.SqlConnection)Database.GetDbConnection();
      if (!conn.ConnectionString.Contains("Password"))
      {
            conn.AccessToken = (new Microsoft.Azure.Services.AppAuthentication.AzureServiceTokenProvider()).GetAccessTokenAsync("https://database.windows.net/").Result;
      }
   }
   ```

   This is so that the application will use its Managed Service Identity when authenticating to the database. If you are running locally, it will search for "Password" in the connection string, and use the connection string stored in `appsettings.Development.json` instead.

1. Strip out the credentials from the generated file `ADS_ConfigContext.cs`

1. In `ADS_ConfigContext.cs`, change references to `System` to instead use `Domain.Models.System`, to avoid conflict with the built-in `System` namespace

## Configuring your own App Registration

The default App Registration configured in `appsettings.Development.template.json`. It's configured by the CI/CD pipeline to have all the right permissions and localhost redirect URLs, and admin consent has already been granted for the required `openid` and `profile` permissions.

If you want to use your own App Registration, the easiest way is to use the one that's configured for you when you deploy the ADP into your own subscription.

1. Look for the `...-Auth` App Registration. Depending on the values you picked for `CompanyCode`, `EnvironmentCode`, and `LocationCode`, it'll be named something like `TP-AUE-DEV-ADP-APP-001-Auth`
   1. `TP` == `CompanyCode`
   2. `AUE` == `LocationCode` (AUstralia East)
   3. `DEV` == `EnvironmentCode`