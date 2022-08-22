# Azure Data Platform

The Azure Data Platform allows you to quickly spin up an end-to-end best practice environment that connects the various Azure Data Services resources together so that you can quickly and securely create ETL jobs using Data Factory, Databricks, Synapse, Purview, Data Lake, etc.

## Superseded in July 2022

This data platform was retired from usage by Telstra Purple at the start of July 2022 due to improvements made by Microsoft on their Cloud Adoption Framework. Check out the following links before deciding to use this platform:

 - https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/cloud-scale-analytics/architectures/data-management-landing-zone
 - https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/cloud-scale-analytics/architectures/data-landing-zone
 - https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/cloud-scale-analytics/architectures/what-is-data-mesh

## Documentation

- [Infrastructure](infrastructure/README.md)
  - [Configuration](infrastructure/docs/configuration.md)
  - [Limitations](infrastructure/docs/limitations.md)
  - [Optional](infrastructure/docs/optional.md)
  - [Pipeline](infrastructure/docs/pipeline.md)
  - [Post Deployment Steps](infrastructure/docs/post-deploy.md)
- [Databases](databases/README.md)
- [Databricks](databricks/README.md)
- [Data Factory](datafactory/README.md)
- [Web App](webapp/README.md)
  - [WebApp Settings](webapp/ADPConfigurator/README.md)
  - [User Guide](webapp/docs/userguide.md)
- [Function Application](function/PowerShell/README.md)

### Prerequisites

Firstly you need to make sure your local environment meets these pre-requisites (you can use Windows, Mac or Linux):

- [VS Code](https://code.visualstudio.com/) - run `choco install vscode` on Windows with [Chocolatey](https://chocolatey.org/)
- [.NET Core 3.1 SDK](https://dotnet.microsoft.com/download/) and [.NET Core 2.1 runtime](https://dotnet.microsoft.com/download/dotnet-core/thank-you/runtime-2.1.23-windows-x64-installer)
- [PowerShell 7.1](https://docs.microsoft.com/en-gb/powershell/scripting/install/installing-powershell?view=powershell-7.1) (can be installed side-by-side with PowerShell 5.1) - run `choco install powershell-core` on Windows with Chocolatey. You will need at least `7.1.0`.
- [Az PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/) at least `5.1.0` - run `Install-Module -Name Az -Force -Verbose` in an admin console
- [DatabricksPS PowerShell module](https://github.com/gbrueckl/Databricks.API.PowerShell) at least `1.6.2.0` - run `Install-Module -Name DatabricksPS -RequiredVersion 1.6.2.0 -Force -Verbose` in an admin console
- [azure.datafactory.tools PowerShell module](https://github.com/SQLPlayer/azure.datafactory.tools) at least `0.17.0` - run `Install-Module -Name azure.datafactory.tools -RequiredVersion 0.17.0 -Force -Verbose`
- [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local) - run `choco install azure-functions-core-tools-3` on Windows with Chocolatey
- [Az.Synapse PowerShell Module](https://www.powershellgallery.com/packages/Az.Synapse/) at least `0.17.0` - run `Install-Module -Name Az.Synapse -Requiredversion 0.17.0`
- [Az.Purview PowerShell Module](https://www.powershellgallery.com/packages/Az.Purview/) at least `0.1.0` - run `Install-Module -Name Az.Purview -Requiredversion 0.1.0`

## License

GNU GENERAL PUBLIC LICENSE - Version 3, 29 June 2007