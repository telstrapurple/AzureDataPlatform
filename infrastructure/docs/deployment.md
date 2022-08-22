# Deploy Azure Data Services

[[_TOC_]]

If we are deploying into a subscription that we don't have owner and Azure AD global rights to we can follow these steps.

## Permissions

1. Service Principal for Azure DevOps Pipelines

- **Important Note!** If certain API permissions or Azure role assignments cannot be granted to the Service Principal, then manual steps will need to be made to allow for a complete end-to-end deployment. See below instructions on what to do when not all permissions are granted.

  - [Allow only resource group privileges](#Allow-only-resource-group-privileges)
  - [Avoid granting Azure AD permissions to Service Principal](#Avoid-granting-Azure-AD-permissions-to-Service-Principal)
    <br> <br>

  1. Ask a System Administrator to create an Azure Azure AD Service Principal. A suggested name is `ADP-DevOps`. Record the `objectId`, `clientId` and `client_secret` in a safe place like LastPass so it can be used to configure the Azure DevOps service connection.
  2. Grant the Service Principal at an Azure subscription `Contributor` and `User Access Administrator` rights.
  3. Grant the application registration the following **Application** API permissions.
     - `Azure SQL Database\app_impersonation`. Requires `Admin consent`. _Note: This and the one below are available via the `APIs my organisation uses` tab when adding a permission in the portal._
     - `Azure SQL Database\user_impersonation` (note: this is a **delegated permission** so technically shouldn't be needed, but the [Microsoft documentation](https://docs.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-service-principal-tutorial#create-a-service-principal-an-azure-ad-application-in-azure-ad) states this is needed)
     - `Azure Active Directory Graph\Application.ReadWrite.OwnedBy`. Requires `Admin consent`. _This is deprecated, but some of the `_-AzAD\*` cmdlets need it still.\_
     - `Azure Active Directory Graph\Directory.Read.All`. Requires `Admin consent`. _This is deprecated, but the `Set-AzSqlServerActiveDirectoryAdministrator` cmdlet needs it still._
     - `Microsoft Graph\Application.ReadWrite.OwnedBy`. Requires `Admin consent`. Note: currently we are using the `Azure Active Directory Graph` permission, but this is deprecated so over time we will shift to using Microsoft Graph as the Microsoft Cmdlets support that and/or we develop Cmdlets ourselves (the key one currently being `New-AzADAppCredential`).
     - `Microsoft Graph\Directory.Read.All`. Requires `Admin consent`.
     - `Microsoft Graph\Group.Create`. Requires `Admin consent`.
     - `Microsoft Graph\GroupMember.ReadWrite.All`. Requires `Admin consent`.
  4. Support [creating Azure AD users/principals in Azure SQL databases](https://docs.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-service-principal-tutorial#create-the-service-principal-user-in-azure-sql-database). Here you have a few options:

     - **_Option 1 - Privileged Roles Administrator approach_**:

       1. Grant the service principal `Privileged Roles Administrator` [Azure AD directory role rights](https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal).
       2. Update the `config.*.json` file with the following JSON where `name-of-group` is the display name of the group `Deploy-SqlAccess.ps1` will create/modify/maintain.

          ```json
            "sqlAccess": {
              "azureADDirectoryReadersRoleADGroup": "name-of-group"
            }
          ```

     - **_Option 2 - Role assignable group approach_**:

       1. Create using the Azure Portal or Azure PowerShell a [role-assignable Azure AD Group](https://docs.microsoft.com/en-us/azure/active-directory/roles/groups-create-eligible).
       2. [Grant this group](https://docs.microsoft.com/en-us/azure/active-directory/roles/groups-assign-role) `Directory Reader` rights.
          - Either set the Azure DevOps service principal as an owner of this group, or add the SQL Server Managed Identity (not the same as the Azure DevOps service principal, it will have the same name as the sql server resource) once the `Deploy-Data.ps1` module is run.
       3. Update the `config.*.json` file with the following JSON where `00000000-0000-0000-0000-000000000000` is the GUID of the Azure AD Group you created in step 1. Note: Display Name of group is also supported here so long as `Microsoft Graph\Directory.Read.All` API has been granted.

          ```json
            "sqlAccess": {
              "azureADDirectoryReadersRoleADGroup": "00000000-0000-0000-0000-000000000000"
            }
          ```

     - **_Option 3 - Directory.Read.All approach_**: The service principal only needs `Directory.Read.All` so it can convert the various service principal object IDs (from the created managed identity principals for various services like Data Factory) into application IDs and then set up database access using the [sid algorithm](https://stackoverflow.com/questions/57818507/use-azure-powershell-runbook-to-add-azuread-user-as-db-owner-to-an-azure-sql-dat); to do this simply set the `azureADDirectoryReadersRoleADGroup` to an empty string in `sqlAccess`. **Note:** this option is required if you don't have Azure AD Premium which is required to create a role-assignable Azure AD Group.

       ```json
         "sqlAccess": {
           "azureADDirectoryReadersRoleADGroup": ""
         }
       ```

2. Azure DevOps Project configuration

   1. Create an Azure DevOps Project in the nominated Azure AD subscription.
   1. Create an empty repository.
   1. Copy the contents of this source code repository into the repository along with a .GIT_COMMIT_HASH file with the Git commit hash we took the code at (so we can check it later).
   1. Create a service connection to Azure Resource Manager per environment, ideally at the subscription level. See below `Access to subscription / resource groups` for more information.

**Note:** This option is not preferred due to the fact it makes it harder to uplift the IP later on and makes Managed Services support harder.

3. Access to subscription/resource groups

   1. Ask the System Administrator of the Azure AD tenancy create a service principal that our deployment pipeline will run as.
      - This account should ideally have at least `Contributor` and `User Access Administrator` rights at the `Subscription` level, if not `Owner`.
      - It also needs permission to be able to remove and add resource locks
   2. If the pipeline Service Principal cannot have `Contributor` and `User Access Administrator` access to an Azure subscription then follow the [Allow only resource group privileges](#Allow-only-resource-group-privileges) instructions.
   3. Create Azure DevOps pipelines from the various `azure-pipelines.yml` files in this repository with an Azure RM connection that runs as the service principal(s) the organisation admin created for us for each environment
   4. Make sure that the Git repository in Azure DevOps has branch policies configured e.g. PRs to Main branch, PRs need at least one on-author reviewer, required/optional checks met for PRs, etc.

4. Create config file(s) - copy `config.dev.json` into a different file e.g. `config.prd.json` and set values in there as appropriate and ensure the Azure DevOps pipelines are configured to reference these JSON file(s)

5. Execute deployments

### Avoid granting Azure AD permissions to Service Principal

If no write access to Azure AD is granted then this solution requires someone to manually to set up service principals, applications registrations and groups so we can perform the rest of the automation in the deployment pipelines.

In that case you need to:

1. Get the System Administrator of Azure to create the necessary Azure AD Groups for the Administrators of the platform. Ask for them to obtain the objectId for each of these groups:

   - A group that will be granted `Contributor` rights to each Resource Group
   - A group that will be granted `Data Factory Contributor` rights to the Azure Data Factory resource
   - A group that will be granted the access policy to get secrets, keys and certificates from the operational (not deployment) Azure Key Vault
   - A group that will be granted `Databricks Contributor` rights to the Azure Databricks resource
   - A group that will be granted `SQL Administrator` rights to the Azure SQL Server instance; make the Azure DevOps Service Principal an owner of this group if you want it to temporarily add itself to this group rather than temporarily taking over admin rights for itself when deploying
   - A group that will be granted access to the Configurator web app
   - A group that will be granted `Storage Blob Data Owner` rights to the data lake storage account
   - A group that will be granted `Directory.Read.All` access to the SQL Server service principal

2. Change the following in `config.*.json`:

   - Set `deployAzureADResources` to `false`.
   - Set `create.azureADGroups` to `false`.
   - Set `resourceGroupContributor` to the appropriate objectId provided in step 1.
   - Set `dataFactoryContributor` to the appropriate objectId provided in step 1.
   - Set `databricksContributor` to the appropriate objectId provided in step 1.
   - Set `keyVaultAdministrator` to the appropriate objectId provided in step 1.
   - Set `sqlAdministrator` to the appropriate objectId provided in step 1.
   - Set `configuratorAdministrator` to the appropriate objectId provided in step 1.
   - Set `dataLakeAdministrator` to the appropriate objectId provided in step 1.
   - Add/Modify `sqlAccess` key as mentioned [above](#Deploy-this-into-a-customer-environment).

Note: There is an additional group in the config called `sqlAdministratorGroupName`. Please adjust this group name to be the same as the group created for SQL Administrative rights (`sqlAdministrator`). The reason this configuration is required is due to the provisioning of the SQL Server through an ARM template requiring both the group Id and group name as input.

3. After the infrastructure pipeline successfully runs, get them to enable an [Azure Automation Run As Account via the Azure Portal](https://docs.microsoft.com/en-us/azure/automation/manage-runas-account#create-a-run-as-account-in-azure-portal).
4. From step 3, obtain the ApplicationId of the identity and add following in `config.*.json`:

   - Set `automationAccountPrincipalId` to the appropriate service principal ID. E.g. `00000000-0000-0000-0000-000000000000`

5. Create an [application and supporting service principal in the Azure Portal](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#register-an-application-with-azure-ad-and-create-a-service-principal) for Databricks.

   - `Name` should be the same name given to the Databricks resource.
   - `Supported account types` as Single tenant.
   - `Redirect URI` is left blank.

6. From step 5, obtain the ApplicationId, the Client Secret and Service Principal ObjectId of the identity and populate the operational Key Vault secrets `databricksApplicationID`, `databricksApplicationKey` and `databricksServicePrincipalID`.
7. Grant the associated [service principal rights to resources using the Azure Portal](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#assign-a-role-to-the-application) from step 5 to:

   - `SQL DB Contributor` on the `sqlServer` Azure resource.
   - `Storage Blob Contributor` on the `dataLake` Azure resource.

8. Create an [application and supporting service principal in the Azure Portal](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#register-an-application-with-azure-ad-and-create-a-service-principal) for the ADP WebApp.

   - `Name` should be a friendly name given to the ADP WebApp.
   - `Supported account types` as Single tenant.
   - `Redirect URI` should be a `web` URL that is the WebApp with the `/signin-oidc` path. E.g. `https://tp-syd-dev-adp-app-001.azurewebsites.net/signin-oidc"`
   - Once the app registration is created, the API Permissions should be granted admin consent (currently it's only `User.Read` which is added by default).
   - In the associated enterprise app:
     - Properties > Enable "User assignment required".
     - Users and groups > Add the group that has access to the ADP WebApp.

9. Update the application manifest for the app registration created in step 8 with the following additional details.

```json
{
  "oauth2AllowIdTokenImplicitFlow": true,
  "groupMembershipClaims": "SecurityGroup",
  "allowPublicClient": null,
  "optionalClaims": {
    "idToken": [
      {
        "name": "groups",
        "source": null,
        "essential": false,
        "additionalProperties": []
      }
    ],
    "accessToken": [
      {
        "name": "groups",
        "source": null,
        "essential": false,
        "additionalProperties": []
      }
    ],
    "saml2Token": []
  }
}
```

### Allow only resource group privileges

If the subscription owner pemissions cannot be granted, then this solution requires someone to manually set up the resource groups and RBAC so the pipeline can perform the rest of the automation in the deployment pipelines.

In that case you need to:

1. Give the `resourceGroup.json` and `resourceGroup.parameters.json` artefact file and ask a System Administrator them to run the ARM template for each resource group we need. E.g. `Administration`, `Compute`, `Data`, `Purview`, `Synapse`, `Network` and `Security`.

   - Note: For Role Based Access Controls, we need the service principal created for the pipeline deploy to have `Contributor` and `User Access Administrator` rights. This is achieved by having a `argPermissions` array like:

   ```json
   "argPermissions": {
     "value": [
       {
         "builtInRoleType": "Contributor",
         "principalId": "00000000-00000-00000-00000-000000000"
       },
       {
         "principalId": "00000000-00000-00000-00000-000000000"
       }
     ]
   }
   ```

   Where `00000000-00000-00000-00000-000000000` is the objectId of the service principle created. Alternatively, they can grant these permissions in the Azure Portal.

2. Change the following in `config.*.json`:

- Set `deploySubscriptionResources` to `false`
- Set `create.resourceGroups` to `false`
- Set the names of the resource groups that the customer created for us in step 1 on the `resourceGroupNames` node.

## Allow BYO Virtual Networks

If you want to use an existing vNet, or vNet(s) then the solution requires them to set up the subnets, network security groups and DDoS appropriately for them. The following steps will help set this up.

1. Provide the Network Administrator with the appropriate IP from this repository.

   1. **Option 1** - Using Deploy-Network.ps1 (_Adopting our our naming standards_)
      - Package up `Deploy-Network.ps1` along with the ARM Templates `networking.General.json` and `networking.Databricks.json` and ask them to execute it with appropriate values and pass us back the result of the outputs.
   2. **Option 2** - Using ARM Templates (_Using their naming standards_)
      - Send the customer `networking.General.json` and `networking.General.json` and ask them to execute it with appropriate values they'd like and pass us back the result of the outputs.

2. From the output of 1. add them to the relevant `config-{env}.json` config file, e.g.:
   ```json
   "generalNetworkIds": {
     "vNetResourceId": "/subscriptions/00000000-00000-00000-00000-000000000/resourcegroups/TP-SYD-DEV-ARG-Network/providers/Microsoft.Network/virtualNetworks/TP-SYD-DEV-ADP-VNT-10.23.0.0",
     "subnetVMResourceId": "/subscriptions/00000000-00000-00000-00000-000000000/resourcegroups/TP-SYD-DEV-ARG-Administration/providers/Microsoft.Network/virtualNetworks/TP-SYD-DEV-ADP-VNT-10.23.0.0/subnets/VirtualMachines",
     "subnetWebAppResourceId": "/subscriptions/00000000-00000-00000-00000-000000000/resourcegroups/TP-SYD-DEV-ARG-Administration/providers/Microsoft.Network/virtualNetworks/TP-SYD-DEV-ADP-VNT-10.23.0.0/subnets/WebApp"
   },
   "databricksNetworkIds": {
     "vNetResourceId": "/subscriptions/00000000-00000-00000-00000-000000000/resourcegroups/TP-SYD-DEV-ARG-Network/providers/Microsoft.Network/virtualNetworks/TP-SYD-DEV-ADP-VNT-10.23.0.0",
     "subnetDBRPublicResourceId": "/subscriptions/00000000-00000-00000-00000-000000000/resourcegroups/TP-SYD-DEV-ARG-Administration/providers/Microsoft.Network/virtualNetworks/TP-SYD-DEV-ADP-VNT-10.22.0.0/subnets/Public",
     "subnetDBRPrivateResourceId": "/subscriptions/00000000-00000-00000-00000-000000000/resourcegroups/TP-SYD-DEV-ARG-Administration/providers/Microsoft.Network/virtualNetworks/TP-SYD-DEV-ADP-VNT-10.22.0.0/subnets/Private"
   }
   ```

### Getting parameters for an ARM deployment

In the `Deploy-*.ps1` files there is a couple of functions that allow you to construct a resource name when performing an ARM deployment:

- `Get-ResourceName($context, $resourceCode[, $suffix])` - e.g. `Get-ResourceName -context $Context -resourceCode "STA" -suffix "003"`
- `Get-StorageResourceName` - Same parameters as above, but it generates a storage account friendly name

Resource names generally follow a convention as defined in the `Get-ResourceName` function:

- `{company code}{delimiter}{location code}{delimiter}{environment code}{delimiter}{app code}{delimiter}{resource code}{delimiter}{suffix}`
- E.g. log analytics (LAW) for Telstra Purple (TP) Azure Data Platform (ADP) deployed into Sydney (SYD) for Development (DEV) with 001 suffix would be: `TP-SYD-DEV-ADP-LAW-001`

In addition there is a function that allows you to create the parameters for an ARM deployment, by combining one or more sources of config together:

- `Get-Params($context[, $with][, $configKey][, $diagnostics][, $purpose])`:
  - `$context` the context object, per above
  - `$with` a statically specified set of parameters as a Hashtable within the PowerShell, which may include calls to `Get-ResourceName`:
    ```powershell
            $lawName = Get-ResourceName -context $Context -resourceCode "LAW" -suffix "001"
            $lawParams = Get-Params -context $Context -configKey "logAnalytics" -with @{
                "lawName" = $lawName;
                "solutionTypes" = $lawSolutions
            }
    ```
    as well as passing in hardcoded and/or parameters passed into the `Deploy-*.ps1` file
  - `$configKey` the name of a key within the `config-{env}.json` file, the values under that key will be turned into parameters
  - `$diagnostics` which should be an object with a `logAnalyticsWorkspaceId`, `diagnosticsStorageAccountId` and `diagnosticsRetentionInDays` property to allow for central diagnostics to be hooked up
  - `$purpose` which is a tag that gets added to the tagsObject. E.g. `Purpose: Data Lake` would appear in the Azure portal if `-purpose "Data Lake"` was specified

## Performing an ARM deployment

There is a function that can be called to perform an Azure Resource Manager deployment, `Invoke-ARM($context, $template, $parameters[, $resourceGroupName][, $location])`, the parameters are:

- `$context` the context object, per above
- `$template` the partial template name e.g. `arm/{$template}.json`
- `$parameters` the parameters object, per above
- Either:
  - `$resourceGroupName` - The name of the resource group to deploy into
  - `$location` - The name of the location to deploy into (if a subscription-wide deployment rather than a resource group deployment)

This function returns the outputs from the ARM template and applies some defaults around name of the deployment and host logging output.

Example:

```powershell
    $lawName = Get-ResourceName -context $Context -resourceCode "LAW" -suffix "001"
            $lawParams = Get-Params -context $Context -configKey "logAnalytics" -with @{
                "lawName" = $lawName;
                "solutionTypes" = $lawSolutions
            }
    $logAnalytics = Invoke-ARM -context $Context -template "logAnalytics" -resourceGroupName $AdminResourceGroupName -parameters $lgaParams

    $diagnostics = @{
        "logAnalyticsWorkspaceId"     = $logAnalytics.logAnalyticsWorkspaceId.value;
    }
```
