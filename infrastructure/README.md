# Azure Data Services Infrastructure

This folder stores all the ARM templates and PowerShell scripts used to deploy all the Azure infrastructure for the Azure Data Services.

[[_TOC_]]

# Folders

- **arm** - Contains Azure Resource Manager (ARM) templates.
- **docs** - Contains documentation and diagrams for the Azure Data Services infrastructure.
- **dsc** - Contains the Desired State Configuration (DSC) PowerShell script which downloads and installs the Azure Data Factory Self-Hosted Integration Runtime.
- **runbooks** - Contains the PowerShell scripts used by the Azure Automation Account.
- **scripts** - Contains the PowerShell scripts used as part of the DevOps pipeline.
- **scripts/schema** - Config schema components, referenced by `/infrastructure/scripts/config.schema.json`

# Solution Architecture

This diagram was [generated](docs/SolutionArchitecture.drawio) using [draw.io](https://www.diagrams.net/).

# Architectural principles

The following architectural principles were employed in the development of this solution:

- **Single Git repository** - with decoupled components so we can make wholescale changes at once, but still work in isolation on different components i.e. using a [monorepo](https://www.atlassian.com/git/tutorials/monorepos) approach
- **Consistent** - naming convention of resources is consistent, tags for resources is consistent, parameters we pass into scripts and ARM templates are consistent, file structures are consistent; once you grasp the basics everything should be easily reasoned about
- **Configurable** - we know different organisations have different requirements and we want to be able to apply configuration of the platform ideally without changing code; there is a [JSON config file](docs/configuration.md) that drives the deployment of a single environment instance
- **Reusabile** - we take a [modular approach](#modularity-model) that layers reusable components together to achieve the end result allowing for some or all of the platform to be easily reused for other solutions/platforms/scenarios in the future
- **Secure** - we take security seriously and apply all possible best practices from a security perspective like security checklist review, least privilege, defensive coding, secure strings, key vaults, managed identities, service endpoints, locking down firewalls, etc.
- **Highly automated creation and update** - we automate everything practical and avoid manual tweaks wherever possible - we want to go from an empty subscription to a working platform with one script run ideally; we also want all scripts to be idempotent so they can be re-run safely at any time to upgrade an environment to the latest configuration

# Modularity model

We use the following model to structure this solution:

- Platform - the end-to-end infrastructure solution, orchestrated by `azure-pipelines.yml`/`deployment-steps.yml` (in Azure DevOps); this is specific to Azure Data Services
  - Modules - groups of related functionality that get deployed together - these are represented by the various `Scripts/Deploy-*.ps1` files, appear as a separate task in Azure DevOps pipelines and can be run independently locally (speeding up debugging) and are portable in of themselves; these are reasonably standalone and can be picked up and repurposed with little effort, but will have some Azure Data Services specific concepts in them
    - Cells - individual units of functionality e.g. a Data Factory, it's diagnostics and it's Integration Runtime - these are represented by the various Azure Resource Manager templates in `arm/*.json`; these are completely standalone and can be immediately reused
- Solutions - the components/content that gets deployed into the platform e.g. web apps, data factory pipelines, Databricks notebooks, SQL schemas, etc.
