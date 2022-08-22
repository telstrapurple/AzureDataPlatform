# Configuration

[[_TOC_]]

The configuration of the Azure Data Services solution deployment happens in three places:

1. The "core parameters" are passed into the various `Deploy-*.ps1` files directly via Azure DevOps variables or `deploy-local.private.json` when running locally. See [pipeline](docs/pipeline.md) for more context.
2. Most values are retrieved from an environment-specific JSON config file e.g. `config-dev.json`; this allows us to configure values that vary by environment (and organisation) within source control in a less wieldy way then a huge number of Azure DevOps variables
3. Hard-coded in the PowerShell script itself; these values don't change across environments or organisations

## Testing template and parameter files

While the deployment PowerShell files don't use the ARM parameter files, we have still included parameter files in `arm/parameters/{template}.parameters.json` so that:

- The individual ARM templates are modular and portable in their own right - simply take the ARM template and its corresponding parameters file
- Help someone consuming / developing to understand what the intended values look like
- Help us validate the templates en masse via the `Test-Parameters.ps1` file (also available via `F5` in VSCode if you select it)

## Context

There is a concept within the automation scripts of a "Context" object that is passed around to the various PowerShell functions that perform the key automation tasks. This "Context" contains configuration values that can be used to vary the specifics of how the infrastructure gets provisioned.

The context object can be created by calling the `Initialize-ADPContext`, which takes two parameters: `-parameters` and `configFilePath`. The former needs to be a Hashtable with the "core properties", which if they have been passed into a script can be accessed from `$PSBoundProperties` and the latter needs to be the file path to the JSON config to be deployed e.g. `(Join-Path $PSScriptRoot $ConfigFile)` if `$ConfigFile` contains the file name and it resides in the same folder as the script.

The values that are available in the `$Context` value are a combination of all of the "core parameters" mentioned above, along with values that are loaded from the `config.{env}.json` file:

- "core parameters" - Per above, e.g. `EnvironmentName`, `EnvironmentCode`, `Location`, `LocationCode`, `TenantId` and `SubscriptionId`
- `CompanyName` - Full name of the company e.g. `Telstra Purple`
- `CompanyCode` - Abbreviated company code e.g. `TP`
- `AppName` - Full name of the application e.g. `Azure Data Services`
- `AppCode` - Abbreviated app code e.g. `ADP`
- `Delimiter` - Delimiter to use when constructing a resource name
- `deployAzureADResources` - Whether or not to deploy Azure AD specific resources (Service Principals, Application Registrations, Groups, etc.).
  - Note: Disabling Azure AD Group creation is possible while still allowing for Service Principals, Managed Identities and Application Registrations. See `create.azureADGroups` below.
- `deploySubscriptionResources` - Whether or not to deploy subscription-level resources (resource groups, Azure Security Centre, Azure Policy, etc.)
- `resourceGroupNames` - Resource group names - object with the following keys: `admin`, `network`, `data`, `databricks`, `security`, `compute`
  - If any of the resource group names have `auto` as the value then the name will be auto-generated using the naming convention and `ARG` as the resource code
- `create` - Boolean flags that designate whether to create certain optional aspects of the infrastructure:
- `create.resourceGroups` - Create the resource groups; set to false if the organisation has pre-provisioned resource groups and make sure their names are specified in `resourceGroupNames`
  - Note: the `compute` resource group will only get created if `create.virtualMachine` is `true` (see below)
  - Note: the `network` resource group will only get created if `create.virtualNetwork` is `true` (see below)
- `create.azureADGroups` - Create if `true`, Find if `false` the necessary Azure AD Groups needed for the Azure Data Services. See below `azureADGroups` for how the find or create works.
  - Note: this setting has no impact on Service Principals, Managed Identities and Application Registrations. See above `deployAzureADResources` to disable this creation.
- `create.asc` - Create an Azure Security Centre instance
- `create.ddosPlan` - Create a DDoS protection plan to attach the vNets to
  - **Warning**: DDoS plans cost over $4,000/month we recommend they are not turned on in non-production and only used when absolutely needed in production with consent of the organisation
- `create.diagnostics` - Enable diagnostics collection from all applicable resources and create the Log Analytics workspace and Storage Account for those logs to funnel to
  - Note: the `diagnosticsRetentionInDays` number of days below.
- `create.virtualNetwork` - Create the virtual network and the resourceGroup `network`; set to false if the organisation has pre-provisioned the virtual network for us and make sure the IDs are specified in `generalNetworkIds` and `databricksNetworkIds`
- `create.networkWatcher` - Create a network watcher; set to false if there is already one in the subscription
- `create.virtualMachine` - Create the virtualMachine(s) and the resourceGroup `compute`; set to false if there is already virtual machines in the subscription or not wanting Azure non self-hosted integration runtimes.
- `create.virtualMachinePowerBiGateway` - Create the virtualMachine(s) and the resourceGroup `compute`; set to false if there is already virtual machines in the subscription or not wanting PowerBI gateways.
- `create.virtualMachinePurview` - Create the virtualMachine(s) and the resourceGroup `compute`; set to false if there is already virtual machines in the subscription or not wanting Azure non self-hosted integration runtimes.
- `create.policyBasic` - Deploy basic policies (currently: all resources deployed to the primary region)
- `create.policyISMAustralia` - Deploy ISM Protected policies
- `create.purview` - Deploy Purview
- `create.sentinel` - Deploy Azure Sentinel
- `create.synapse` - Deploy Azure Synapse
- `create.natgateway` - Deploy a NAT gateway to support network routing.
- `create.udr` - Deploy a route tables for the virtual networks (general and networks) to support network routing.
- `azureADGroups` - If `create.azureADGroups` is `true`, the friendly display name of the Azure AD Groups you want to create. If `create.azureADGroups` is `false`, the existing, pre-created objectId of the Azure AD Group to be used.
  - `resourceGroupContributor`: The friendly display name or the objectId of the Azure AD Group that will be granted Contributor rights to each Resource Group
  - `dataFactoryContributor`: The friendly display name or the objectId of the Azure AD Group that will be granted Data Factory Contributor rights to the Azure Data Factory resource
  - `databricksContributor`: The friendly display name or the objectId of the Azure AD Group that will be granted Databricks Contributor rights to the Azure Databricks resource
  - `keyVaultAdministrator`: The friendly display name or the objectId of the Azure AD Group that will be granted the access policy to get secrets, keys and certificates from the operational (not deployment) Azure Key Vault
  - `sqlAdministrator`: The friendly display name or the objectId of the Azure AD Group that will be granted SQL Administrator rights to the Azure SQL Server instance
- `diagnosticsRetentionInDays` - Number of days to retain logs and metrics in the diagnostics Storage Account. Between 0 and 365 days. 0 retains indefinitely.
- _Various others from `config.{env}.json`_ - Any other items in the JSON config will automatically be loaded into the context and be available via the `configKey` parameter in the `Get-Params` function, i.e. will be directly turned into ARM template parameter values, or any other usage the scripts make of them

## Changing the config file

To aid the local dev experience, the Azure Data Services has a [JSON schema](https://json-schema.org/) that defines the shape and validation constraints of the `config.{env}.json` files.

As the ADP is developed and improved and new features are added, the JSON schema will need to be updated accordingly.

The root schema can be found at `/infrastructure/scripts/config.schema.json` ([link](./scripts/config.schema.json)).

### Schema Structure

The schema file follows the same module pattern as the deployment scripts. Each deployment module (for example, `Deploy-Identities.ps1` or `Deploy-Network.ps1`) has a corresponding schema file that it contributes to the root schema. You can find the per-module 'sub'-schema files in `./infrastructure/scripts/schema`

Each sub-schema file is a complete schema file in its own right, and defines the requirements of its corresponding `Deploy-xyz.ps1` deployment script. The root schema (`config.schema.json`) merges all the sub-schemas using an `allOf` element ([docs](https://json-schema.org/understanding-json-schema/reference/combining.html#allof)) and cross-schema `$ref` references ([docs](http://niem.github.io/json/reference/json-schema/references/))

- `/infrastructure/scripts/`
  - [`config.schema.json`](/infrastructure/scripts/config.schema.json) - The root schema. Declares some top-level properties and merges in the sub-schema files with `allOf` and `$ref`
  - `schema/`
    - [`config.common.schema.json`](/infrastructure/scripts/schema/config.common.schema.json) - A variety of schema types used by several different sub-schemas
    - [`deploy-identities.schema.json`](/infrastructure/scripts/schema/deploy-identities.schema.json) - Schema defining the config file elements needed by the `Deploy-Identities.ps1` deployment script
    - [`deploy-core.schema.json`](/infrastructure/scripts/schema/deploy-core.schema.json) - Schema defining the config file elements needed by the `Deploy-Core.ps1` deployment script
    - etc etc
    - `databases/` - additional sub-schemas for deployment components outside the `/infrastructure` directory.
      - [`deploy-databases.schema.json`](/infrastructure/scripts/schema/databases/deploy-databases.schema.json) - Schema defining the config file elements needed by the `/databases/deployment.ps1` script. `/databases/deployment.ps1` uses the same `config.{env}.json` config file so its types are included in `deploy-databases.schema.json` so they are merged into the root schema.
    - `datafactory/`
      - [`deploy-datafactory-app.schema.json`](/infrastructure/scripts/schema/datafactory/deploy-datafactory-app.schema.json) - Schema defining the config file elements needed by the `/datafactory/deployment.ps1` script. `/datafactory/deployment.ps1` uses the same `config.{env}.json` config file so its types are included in `deploy-datafactory-app.schema.json` so they are merged into the root schema.
    - `databricks/`
      - [`deploy-databricks-app.schema.json`](/infrastructure/scripts/schema/databricks/deploy-databricks-app.schema.json) - Schema defining the config file elements needed by the `/databricks/deployment.ps1` script. `/databricks/deployment.ps1` uses the same `config.{env}.json` config file so its types are included in `deploy-databricks-app.schema.json` so they are merged into the root schema.

### Design priorities for config file JSON Schema

The inclusion of a JSON schema for `config.{env}.json` serves several purposes. You should keep these purposes in mind when you're modifying the schema;

- Build-time validation - A fail-fast gate that allows CI builds and deployment pipeline runs to fail immediately if the config file is invalid.
- Design-time validation - When authoring a `config.{env}.json` file, ensuring that you can know as soon as possible that you've made a mistake, or have confidence that the file is correct.
- Design-time assistance - When authoring a `config.{env}.json` file, allow your JSON Schema-aware IDE (for example, VS Code) to provide in-editor;
  - validation - by default, VS Code uses yellow squiggles and tooltips to indicate validation issues
  - allowed values and types - by default, VS Code shows the allowed values and types (eg, string, boolean, array, object, permitted enumeration values, etc) as tooltips
  - documentation - based on the `description` elements in the schema. These are shown in VS Code as tooltips when you hover over an element whose schema definition includes a `description`.

### Editing JSON schema

You can find the [json-schema.org](https://json-schema.org) 'human-friendly' documentation for understanding JSON Schema at [Understanding JSON Schema](https://json-schema.org/understanding-json-schema/index.html).

When you're authoring or modifying the schema, you should strive to follow these guidelines which contribute to the design priorities above ☝;

- Completeness: Include schema definitions for _every_ property. Where possible and knowable;
  - add properties to the `required` array to make them mandatory [docs](http://json-schema.org/understanding-json-schema/reference/object.html#required-properties)
  - add a `type` definition to constrain the type (is it a string, boolean, number, integer, object, array?) [docs](https://json-schema.org/understanding-json-schema/basics.html#the-type-keyword)
- Correctness: Where possible, define the schema such that a conforming config file is known to be correct.
  - Get the `required` properties correct
  - Add min/max/range/pattern/uniqueness/etc constraints [docs](https://json-schema.org/understanding-json-schema/reference/index.html) (for example, see docs for [string](https://json-schema.org/understanding-json-schema/reference/string.html) and [numeric types](https://json-schema.org/understanding-json-schema/reference/numeric.html))
  - If known, add the set of allowed values in an `enum` property ([docs](https://json-schema.org/understanding-json-schema/reference/generic.html#enumerated-values)). This is especially handy if the properties are being passed through to an ARM template that defines the allowed values.
  - In some cases it's not possible (or not reasonably straightforward) to define a schema that is perfectly correct. In these cases do the best you can within the constraints of JSON Schema and document any important additional restrictions in the `description` element. At worst, the deployment pipeline will fail at runtime.
    - In particular, defining a particular constraint for an element based on the value of a `create.{flag-name}` flag doesn't appear to be possible. For example, if `create.asc` is false, then the property object `azureSecurityCentre` isn't mandatory, but it doesn't seem possible to define this relationship in schema.
- Documenting: Put `description` elements on every property. These show up in the IDE, usually as on-hover tooltips. Information you should consider adding include;
  - What the field means
  - Where and how it's used - What consumes the value? What's the unit of measure if it's not obvious from the name? How will the value affect the deployment process? (for example, `create.{flag-name}` properties enable or disable deployment of specific parts of the ADP)
  - Is it passed to some other system? Can you link to documentation that describes how the downstream system uses it? For example, if the value is passed to an ARM template, can you link to the ARM resource provider documentation?
  - How else can you discover the allowed values? For example, there are far too many Virtual Machine SKUs to list in the schema (and new ones are added all the time), but there's a simple one-line cmdlet you can run to discover the allowed SKUs that you can include in the `description`.

### Testing the config file against the schema

Use the test harness `/infrastructure/scripts/Test-Schema.ps1` ([link](/infrastructure/scripts/Test-Schema.ps1)). By default it tests `config.dev.json` against `config.schema.json`.

If the file at `-configFilePath` is valid according to the schema at `-schemaFilePath`, the script will print `True`. Otherwise it will print a descriptive error.

Requires Powershell Core 6+.
