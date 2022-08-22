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

    [Parameter(Mandatory = $false)]
    [string] $azureADGroupId_resourceGroupContributor,

    [Parameter(Mandatory = $false)]
    [string] $azureADGroupId_keyVaultAdministrator
)

Set-StrictMode -Version "Latest"
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "./functions/adp.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/keyvault.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/storage.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/azuread.psm1") -Force -Verbose:$false

$Context = Initialize-ADPContext -parameters $PSBoundParameters -configFilePath (Join-Path $PSScriptRoot $ConfigFile)

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

        ##############################################################################
        # Resource Groups
        ##############################################################################

        if ($Context.create.resourceGroups -and $Context.deploySubscriptionResources) {
            # Get the Resource Group Role Assignment. If PrincipalId is string.Empty, then pass empty array.
            if ($azureADGroupId_resourceGroupContributor) {
                $roleAssignments = @(
                    @{
                        "builtInRoleType" = "Contributor"
                        "principalId"     = $azureADGroupId_resourceGroupContributor;
                    }
                )
            }
            else {
                $roleAssignments = @()
                Write-Warning "⚠️  Skipping role assignment for Resource Groups Contributors, this is likely because of no privileges on the Azure AD tenancy $TenantId; follow documentation to manually configure this otherwise access will be denied."
            }

            Write-Host "Creating resource groups in parallel job. Please wait for output."
            $job = $Context.resourceGroupNames.Keys | ForEach-Object -AsJob -Parallel {
                Import-Module (Join-Path $using:PSScriptRoot "./functions/adp.psm1") -Force -Verbose:$false
                $hash = $using:Context.resourceGroupNames
                $value = $hash[$_]

                if (-not $using:Context.create.virtualMachine -and $_ -eq "compute") {
                    # Dont create the Compute resource group, breaking out of this loop.
                    break;
                }

                if (-not $using:Context.create.virtualNetwork -and $_ -eq "network") {
                    # Dont create the vNet resource group, breaking out of this loop.
                    break;
                }

                if ($value -like "*Managed*") {
                    # Managed resource groups are created by the resource that manages them, breaking out of this loop.
                    break;
                }

                Write-Host "$(Get-Date -Format FileDateTimeUniversal) Ensuring resource group $($value) exists"
                $argAdminParams = Get-Params -context $using:Context -with @{
                    "argName"        = $value
                    "resourceLock"   = $true;
                    "argPermissions" = $using:roleAssignments
                    "azureLocation"  = $using:Location;
                    "subscriptionId" = $using:SubscriptionId
                }
                Invoke-ARM -context $using:Context -template "resourceGroup" -parameters $argAdminParams -Location $using:Location
            }
            $job | Wait-Job | Receive-Job
        }
        else {
            $Context.resourceGroupNames
        }

        ###############################################################################
        ## Log Analytics and diagnostics
        ###############################################################################

        if ($Context.create.diagnostics) {
            $lawSolutions = @()
            if ($Context.create.sentinel) {
                Write-Verbose  ((Get-Date -f "hh:mm:ss tt") + " - " + "Adding Azure Sentinel to Log Analytics");
                $lawSolutions = $Context.logAnalyticsSolutions
                $lawSolutions += "SecurityInsights"
            }
            else {
                $lawSolutions = $Context.logAnalyticsSolutions
            }

            $lawName = Get-ResourceName -context $Context -resourceCode "OMS" -suffix "001"
            $lawParams = Get-Params -context $Context -configKey "logAnalytics" -with @{
                "lawName"       = $lawName;
                "solutionTypes" = $lawSolutions
            }
            $logAnalytics = Invoke-ARM -context $Context -template "logAnalytics" -resourceGroupName $Context.resourceGroupNames.admin -parameters $lawParams

            $diagnosticsStorageParams = Get-Params -context $Context -configKey "diagnosticsStorage" -purpose "Diagnostics" -with @{
                "staName"                    = Get-ResourceName -context $Context -resourceCode "STA" -suffix "001";
                "subnetIdArray"              = @();
                "bypassNetworkDefaultAction" = "None";
                "networkDefaultAction"       = "Allow";
            }
            $diagnosticsStorage = Invoke-ARM -context $Context -template "storageAccount" -resourceGroupName $Context.resourceGroupNames.admin -parameters $diagnosticsStorageParams

            $diagnostics = @{
                "logAnalyticsWorkspaceId"     = $logAnalytics.logAnalyticsWorkspaceId.value;
                "diagnosticsStorageAccountId" = $diagnosticsStorage.storageAccountId.value;
                "diagnosticsRetentionInDays"  = $Context.diagnosticsRetentionInDays
            }
        }
        else {
            $diagnostics = @{
                "logAnalyticsWorkspaceId"     = "";
                "diagnosticsStorageAccountId" = "";
                "diagnosticsRetentionInDays"  = 0;
            }
        }

        Publish-Variables -vars @{ "diagnosticsObject" = $diagnostics; }

        ###############################################################################
        ## Microsoft Insights
        ###############################################################################

        if ($Context.create.diagnostics -and $Context.deploySubscriptionResources) {
            $insParams = Get-Params -context $Context -diagnostics $diagnostics
            Invoke-ARM -context $Context -template "insights" -parameters $insParams -Location $Location
        }

        ###############################################################################
        ## Code Storage
        ###############################################################################

        $codeStorageParams = Get-Params -context $Context -configKey "codeStorage" -diagnostics $diagnostics -purpose "Deployment code storage" -with @{
            "staName"                    = Get-ResourceName -context $Context -resourceCode "STA" -suffix "002";
            "subnetIdArray"              = @();
            "bypassNetworkDefaultAction" = "None";
            "networkDefaultAction"       = "Allow"; # Todo: change to Deny, AzureServices and add current IP temporarily
        }
        $codeStorage = Invoke-ARM -context $Context -template "storageAccount" -resourceGroupName $Context.resourceGroupNames.admin -parameters $codeStorageParams

        $codeStorageAccountName = $codeStorage.storageAccountName.value
        $codeStorageResourceGroupName = $Context.resourceGroupNames.admin

        $codeStorageContext = Get-StorageContext -Name $codeStorageAccountName -ResourceGroupName $codeStorageResourceGroupName
        Set-StorageContainer -Context $codeStorageContext -Name "code"
        Set-StorageContainer -Context $codeStorageContext -Name "runbooks"

        Publish-Variables -vars @{"codeStorageAccountName" = $codeStorageAccountName; "codeStorageResourceGroupName" = $codeStorageResourceGroupName; }

        ##############################################################################
        # Deployment Key Vault
        ##############################################################################

        $deployerAzureAdObjectId = Get-CurrentUserAzureAdObjectId;
        $deploymentKeyVaultParams = Get-Params -Context $Context -ConfigKey 'deploymentSecretsKeyVault' -Diagnostics $diagnostics -Purpose "Deployment secrets" -With @{
            "akvName"          = Get-ResourceName -context $Context -resourceCode "KV" -suffix "002";
            "tenantId"         = $TenantId;
            "deployerObjectId" = $deployerAzureAdObjectId;
        }
        # Add in the KeyVault Administrator if it doesn't already exist
        if (-not [String]::IsNullOrWhiteSpace($azureADGroupId_keyVaultAdministrator)) {
            if (-not $deploymentKeyVaultParams.ContainsKey('additionalAccessPolicies')) { $deploymentKeyVaultParams.Add('additionalAccessPolicies', @()) }
            $HasKVAdmin = $deploymentKeyVaultParams['additionalAccessPolicies'] | Where-Object { $_.objectId -eq 'azureADGroupId_keyVaultAdministrator' }
            if ($null -eq $HasKVAdmin) {
                Write-Verbose "Adding keyVaultAdministrator to Access Policies"
                $deploymentKeyVaultParams['additionalAccessPolicies'] += @{
                    "objectId"    = $azureADGroupId_keyVaultAdministrator
                    "permissions" = @{
                        "certificates" = @("Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers")
                        "keys"         = @("Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore")
                        "secrets"      = @("Get", "List", "Set", "Delete", "Recover", "Backup", "Restore")
                    }
                    "tenantId"    = $TenantId
                }
            }
        }

        $deploymentKeyVault = Invoke-ARM -context $Context -resourceGroupName $Context.resourceGroupNames.security -template "keyVault.basic" -parameters $deploymentKeyVaultParams
        $deploymentKeyVaultName = $deploymentKeyVault.keyVaultName.value

        Publish-Variables -vars @{ "deploymentKeyVaultName" = $deploymentKeyVaultName; }

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