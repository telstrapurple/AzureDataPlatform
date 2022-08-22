#Requires -Module Az.Synapse
[CmdletBinding(SupportsShouldProcess = $true)]
Param (
    [ValidatePattern("[a-zA-Z0-9\-]{3,24}")]
    [Parameter(Mandatory = $true)]
    [string] $EnvironmentName,

    [Parameter(Mandatory = $true)]
    [ValidatePattern("[a-zA-Z0-9]{1,5}")]
    [string] $EnvironmentCode,

    [Parameter(Mandatory = $true)]
    [ValidatePattern("[a-zA-Z0-9]{1,5}")]
    [string] $Location,

    [Parameter(Mandatory = $true)]
    [ValidatePattern("[a-zA-Z0-9\-]{3,24}")]
    [string] $LocationCode,

    [Parameter(Mandatory = $true)]
    [string] $TenantId,

    [Parameter(Mandatory = $true)]
    [string] $SubscriptionId,

    [Parameter(Mandatory = $false)]
    [string] $ConfigFile = "config.$($EnvironmentCode.ToLower()).json",

    [Parameter(Mandatory = $true)]
    [string] $diagnosticsObject,

    [Parameter(Mandatory = $true)]
    [string] $databricksNetworkObject,

    [Parameter(Mandatory = $true)]
    [string] $generalNetworkObject,

    [Parameter(Mandatory = $true)]
    [string] $deploymentKeyVaultName,

    [Parameter(Mandatory = $true)]
    [string] $azureADGroupId_sqlAdministrator,

    [Parameter(Mandatory = $false)]
    [string] $azureADGroupId_dataLakeAdministrator

)

Set-StrictMode -Version "Latest"
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "./functions/adp.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/keyvault.psm1") -Force -Verbose:$false
Import-Module -Name 'Az.Synapse' -RequiredVersion '0.17.0' -Force -Verbose:$false

$Context = Initialize-ADPContext -parameters $PSBoundParameters -configFilePath (Join-Path $PSScriptRoot $ConfigFile)
$diagnostics = ConvertFrom-JsonToHash -Object $diagnosticsObject
$databricksNetwork = ConvertFrom-JsonToHash -Object $databricksNetworkObject
$generalNetwork = ConvertFrom-JsonToHash -Object $generalNetworkObject

try {

    if ($VerbosePreference -eq "SilentlyContinue" -and $Env:SYSTEM_DEBUG) {
        $VerbosePreference = "Continue"
    }

    if (-not $pscmdlet.ShouldProcess("Deploy with powershell")) {
        Write-Verbose "-WhatIf is set, will not execute deployment."

        Write-Host "Deploy would proceed with the following parameters"
        $Context | Format-Table | Out-String | Write-Host
    }
    else {
        $Context | Format-Table | Out-String | Write-Verbose

        ###############################################################################
        ## SQL Server
        ###############################################################################

        # Need to set a secret value and generate if it doesn't already exist - so we don't create another version of the secret every time we (re)deploy
        Write-Host "Getting / generating SqlServerAdminPassword secret"
        $sqlServerAdminPassword = Get-OrSetKeyVaultGeneratedSecret -keyVaultName $deploymentKeyVaultName -secretName "SqlServerAdminPassword" `
            -generator { Get-RandomPassword }

        $sqlServerParams = Get-Params -context $Context -diagnostics $diagnostics -with @{
            "sqlServerName"                 = (Get-ResourceName -context $Context -resourceCode "SQL" -suffix "001").ToLowerInvariant();
            "sqlAdministratorLoginUsername" = $Context.sqlUsernames.admin;
            "sqlAdministratorLoginPassword" = $sqlServerAdminPassword;
            "azureTenantId"                 = $TenantId;
            "subnetIdArray"                 = @($databricksNetwork.subnetDBRPublicResourceId, $generalNetwork.subnetVMResourceId, $generalNetwork.subnetWebAppResourceId);
            "azureADAdminDisplayName"       = $Context.azureADGroups.sqlAdministratorGroupName;
            "azureADAdminSid"               = $azureADGroupId_sqlAdministrator;
        }
        $sqlServer = Invoke-ARM -context $Context -template "sqlServer" -resourceGroupName $Context.resourceGroupNames.data -parameters $sqlServerParams
        $sqlServerName = $sqlServer.sqlServerName.value

        Publish-Variables -vars @{
            "sqlServerResourceId"        = $sqlServer.sqlServerResourceId.value;
            "sqlServerName"              = $sqlServer.sqlServerName.value;
            "sqlServerResourceGroupName" = $Context.resourceGroupNames.data;
            "sqlServerDomainName"        = $sqlServer.sqlServerFQDN.value;
            "sqlServerManagedIdentity"   = $sqlServer.sqlServerManagedIdentity.value;
        }

        ###############################################################################
        ## Data Lake
        ###############################################################################
        $dataLakeParams = Get-Params -context $Context -configKey "dataLake" -diagnostics $diagnostics -purpose "Data Lake" -with @{
            "staName"                    = Get-ResourceName -context $Context -resourceCode "STA" -suffix "003";
            "defaultContainerName"       = "datalakestore";
            "isDataLake"                 = $true;
            "bypassNetworkDefaultAction" = "AzureServices"
            "networkDefaultAction"       = "Deny"
        }
        if (-not $dataLakeParams.ContainsKey('subnetIdArray')) { $dataLakeParams.Add('subnetIdArray', @()) }
        # Add Default Subnets at the beginning of the array
        $dataLakeParams['subnetIdArray'] = @($generalNetwork.subnetWebAppResourceId, $generalNetwork.subnetVMResourceId, $databricksNetwork.subnetDBRPublicResourceId) + $dataLakeParams['subnetIdArray']

        $dataLake = Invoke-ARM -context $Context -template "storageAccount" -resourceGroupName $Context.resourceGroupNames.data -parameters $dataLakeParams
        Publish-Variables -vars @{
            "dataLakeStorageAccountName" = $dataLake.storageAccountName.value;
            "dataLakeResourceId"         = $dataLake.storageAccountId.value
        }

        # Give Azure AD Group Storage Blob Data Owner rights over the data lake
        $dataLakeRoleParams = Get-Params -context $Context -with @{
            "principalId"     = $azureADGroupId_dataLakeAdministrator;
            "builtInRoleType" = "Storage Blob Data Owner";
            "resourceId"      = $dataLake.storageAccountId.value;
            "roleGuid"        = "guidGrouptoDataLake"; # To keep idempotent, dont change this string after first run
        }
        Invoke-ARM -context $Context -template "roleAssignment" -resourceGroupName $Context.resourceGroupNames.data -parameters $dataLakeRoleParams

        #Publish the data lake file system storage endpoint to pre-populate the SQL configuration data
        Get-OrSetKeyVaultSecret -keyVaultName $deploymentKeyVaultName -secretName "dataLakeStorageEndpoint" -secretValue ($dataLake.storageAccountPrimaryEndpoints.value).Replace(".blob.", ".dfs.") | Out-Null

        ###############################################################################
        ## Config DB
        ###############################################################################

        $sqlConfigDbParams = Get-Params -context $Context -diagnostics $diagnostics -configKey "configDatabase" -with @{
            "sqlServerName" = $sqlServerName;
        }
        $configDb = Invoke-ARM -context $Context -template "sqlDatabase" -resourceGroupName $Context.resourceGroupNames.data -parameters $sqlConfigDbParams

        ###############################################################################
        ## Stage DB
        ###############################################################################

        $sqlStageDbParams = Get-Params -context $Context -diagnostics $diagnostics -configKey "stageDatabase" -with @{
            "sqlServerName" = $sqlServerName;
        }
        $stageDb = Invoke-ARM -context $Context -template "sqlDatabase" -resourceGroupName $Context.resourceGroupNames.data -parameters $sqlStageDbParams

        $databasesObject = @{
            "Stage"  = $stageDb.databaseName.value;
            "Config" = $configDb.databaseName.value;
        }
        Publish-Variables -vars @{"databasesObject" = $databasesObject; }

        ###############################################################################
        ## Synapse Workspace
        ###############################################################################
        if ($Context.create.synapse) {
            # Need to set a secret value and generate if it doesn't already exist - so we don't create another version of the secret every time we (re)deploy
            Write-Host "Getting / generating SqlServerAdminPassword secret"
            $synapseAdminPassword = Get-OrSetKeyVaultGeneratedSecret -keyVaultName $deploymentKeyVaultName -secretName "SynapseSqlAdminPassword" `
                -generator { Get-RandomPassword }

            $synapseWorkspaceName = (Get-ResourceName -context $Context -resourceCode "SYN" -suffix "001").ToLower() # workspace name must be lower

            $storageAccountName = Get-ResourceName -context $Context -resourceCode "STA" -suffix "005"
            if (Get-AzStorageAccount -ResourceGroupName $Context.resourceGroupNames.data -Name $storageAccountName -ErrorAction SilentlyContinue) {
                $isNewStorageAccount = $false
            }
            else {
                $isNewStorageAccount = $true
            }

            $defaultFileSystemName = (Get-ResourceName -context $Context -resourceCode "STA" -suffix "005-fs").ToLower() # file system name must be lower

            $SubnetIdArray = @($databricksNetwork.subnetDBRPublicResourceId, $generalNetwork.subnetVMResourceId, $generalNetwork.subnetWebAppResourceId)
            $SubnetIdArray = @($databricksNetwork.subnetDBRPrivateResourceId) + $SubnetIdArray

            $synapseParams = Get-Params -context $Context -diagnostics $diagnostics -configKey "synapse" -with @{
                "synapseName"                          = $synapseWorkspaceName;
                "defaultDataLakeStorageAccountName"    = $storageAccountName;
                "defaultDataLakeStorageFilesystemName" = $defaultFileSystemName;
                "sqlAdministratorLogin"                = $Context.sqlUsernames.synapseAdmin;
                "sqlAdministratorLoginPassword"        = $synapseAdminPassword;
                "subnetIdArray"                        = $SubnetIdArray
                "managedResourceGroupName"             = $Context.resourceGroupNames.synapse;
                "groupObjectId"                        = $azureADGroupId_sqlAdministrator;
                "storageRoleUniqueIdServicePrincipal"  = "guidStorageRoleUniqueIdServicePrincipal"; # To keep idempotent, dont change this string after first run
                "storageRoleUniqueIdGroup"             = "guidstorageRoleUniqueIdGroup"; # To keep idempotent, dont change this string after first run
                "isNewStorageAccount"                  = $isNewStorageAccount;
            }
            $synapse = Invoke-ARM -context $Context -template "synapse" -resourceGroupName $Context.resourceGroupNames.data -parameters $synapseParams

            Publish-Variables -vars @{
                "synapseWorkspaceName"           = $synapseWorkspaceName;
                "synapseSQLPoolName"             = $Context.synapse.sqlPoolName;
                "synapseStorageAccountName"      = $storageAccountName;
                "synapseStorageAccountID"        = $synapse.storageAccountId.Value;
                "synapseStorageAccountContainer" = $defaultFileSystemName;
            }
            # Check whether a Managed Private Endpoint is required and whether it has been deployed yet or not
            # Looks for whether we are setting them first so no need to check if they are created if we don't use them
            Write-Host -ForegroundColor Magenta "$(Get-Date -Format FileDateTimeUniversal) Checking whether to deploy Managed Private Endpoints.`r`n"
            if ($Context.synapse.useManagedPrivateEndpoints) {
                # We are expecting Managed Private Endpoints, so let's build the name string
                Write-Host -ForegroundColor Magenta "$(Get-Date -Format FileDateTimeUniversal) Set name for Managed Private Endpoints.`r`n"
                $mpeDataLake = "synapse-mpe-datalake--$synapseWorkspaceName-$storageAccountName"
                # Now check whether it has been created
                Write-Host -ForegroundColor Magenta "$(Get-Date -Format FileDateTimeUniversal) Checking whether Managed Private Endpoint already exists.`r`n"
                $mpeExists = Get-AzSynapseManagedPrivateEndpoint -WorkspaceName $synapseWorkspaceName -Name $mpeDataLake -ErrorAction SilentlyContinue
                if (-not($mpeExists)) {
                    Write-Host -ForegroundColor Magenta "$(Get-Date -Format FileDateTimeUniversal) Defining new Managed Private Endpoint.`r`n"
                    # We still needd to create the Managed Private Endpoint, so let's write out the file content
                    $mpeDefinition = @{}
                    $mpeDefinition.Add("Name", "synapse-mpe-datalake--$synapseWorkspaceName-$storageAccountName")
                    $mpeProperties = @{"privateLinkResourceId" = "/subscriptions/$subscriptionId/resourceGroups/$($Context.resourceGroupNames.data)/providers/Microsoft.Storage/storageAccounts/$storageAccountName"; "groupId" = "dfs" }
                    $mpeDefinition.Add("properties", $mpeProperties)

                    # Write out to a definition file - overwrite anything that is there
                    Write-Host -ForegroundColor Magenta "$(Get-Date -Format FileDateTimeUniversal) Updating definition file.`r`n"
                    Set-Content -Path "$PSScriptRoot/synapseManagedPrivateEndpoint.private.json" -Value $(ConvertTo-Json $mpeDefinition) -Force

                    # Now that we have the defintion file, we can create the endpoint
                    Write-Host -ForegroundColor Magenta "$(Get-Date -Format FileDateTimeUniversal) Creating new Managed Private Endpoint.`r`n"
                    New-AzSynapseManagedPrivateEndpoint -WorkspaceName $synapseWorkspaceName -Name $mpeDataLake -DefinitionFile "$PSScriptRoot/synapseManagedPrivateEndpoint.private.json" | Out-Null
                    Write-Host -ForegroundColor Green "`r`n✔️  $(Get-Date -Format FileDateTimeUniversal) Managed Private Endpoint created for default Data Lake Storage.`r`n"
                }

                # Next we need to check if the Private Endpoint has been approved, but first need to wait until it is fully provisioned
                $counter = 60
                $managedEndpoint = $null
                do {
                    $managedEndpoint = Get-AzSynapseManagedPrivateEndpoint -WorkspaceName $synapseWorkspaceName -Name $mpeDataLake
                    Start-Sleep -seconds 1
                    $counter--
                    if ($counter -le 0) { throw "$(Get-Date -Format FileDateTimeUniversal) Provisioning of Managed Private Endpoint failed - timeout exceeded.`r`n" }
                }
                until ($managedEndpoint.Properties.ProvisioningState -eq 'Succeeded')

                Write-Host -ForegroundColor Magenta "$(Get-Date -Format FileDateTimeUniversal) Managed Private Endpoint : $($managedEndpoint).`r`n"

                Write-Host -ForegroundColor Magenta "$(Get-Date -Format FileDateTimeUniversal) Managed Private Endpoint state : $($managedEndpoint.Properties.ConnectionState.Status).`r`n"
                if ($managedEndpoint.Properties.ConnectionState.Status -eq 'Pending') {
                    Write-Host -ForegroundColor Magenta "$(Get-Date -Format FileDateTimeUniversal) Managed Private Endpoint still in Pending state - starting approval process.`r`n"

                    # Get the variables to use for approval
                    $mpeResourceId = $managedEndpoint.Properties.PrivateLinkResourceId
                    $mpeConnectionId = $(Get-AzPrivateEndpointConnection -PrivateLinkResourceId $mpeResourceId).Id
                    $approval = Approve-AzPrivateEndpointConnection -ResourceId $mpeConnectionId
                    Write-Host -ForegroundColor Green "`r`n✔️  $(Get-Date -Format FileDateTimeUniversal) Managed Private Endpoint status is $($approval.PrivateLinkServiceConnectionState.Status).`r`n"
                }
            }

            # Set the Azure AD admin to the SQL admin group
            Set-AzSynapseSqlActiveDirectoryAdministrator -ResourceGroupName $Context.resourceGroupNames.data -WorkspaceName $synapseWorkspaceName -DisplayName $Context.azureADGroups.sqlAdministratorGroupName  | Out-Null
            Write-Host -ForegroundColor Green "`r`n✔️  $(Get-Date -Format FileDateTimeUniversal) Synapse Azure AD admin successfully set to $azureADGroupId_sqlAdministrator.`r`n"
            # Role-base access control
            # Only apply if it doesn't already exist as it doesn't accept adding twice
            if (-not (Get-AzSynapseRoleAssignment -WorkspaceName $synapseWorkspaceName -RoleDefinitionName "Synapse Administrator" -ObjectId $azureADGroupId_sqlAdministrator)) {
                $roleAssignment = New-AzSynapseRoleAssignment -WorkspaceName $synapseWorkspaceName -RoleDefinitionName "Synapse Administrator" -ObjectId $azureADGroupId_sqlAdministrator

                if ($roleAssignment) {
                    Write-Host -ForegroundColor Green "`r`n✔️  $(Get-Date -Format FileDateTimeUniversal) Synapse Role assignment 'Synapse Administrator' completed successfully.`r`n"
                }
            }
            else {
                Write-Host -ForegroundColor Green "`r`n✔️  $(Get-Date -Format FileDateTimeUniversal) Synapse Role assignment 'Synapse Administrator' already assigned for $azureADGroupId_sqlAdministrator `r`n"
            }
        }
    }
}
catch {
    Write-Host -ForegroundColor Red "Caught an exception of type $($_.Exception.GetType())"
    Write-Host -ForegroundColor Red $_.Exception.Message

    if ($_.ScriptStackTrace) {
        Write-Host -ForegroundColor Red $_.ScriptStackTrace
    }

    if ($_.Exception.InnerException) {
        Write-Host -ForegroundColor Red "Caused by: $($_.Exception.InnerException.Message)"
    }

    throw
}
