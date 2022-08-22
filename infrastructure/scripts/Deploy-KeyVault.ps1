#Requires -Module DatabricksPS
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
    [string] $dataFactoryPrincipalId,

    [Parameter(Mandatory = $true)]
    [string] $databricksNetworkObject,

    [Parameter(Mandatory = $true)]
    [string] $generalNetworkObject,

    [Parameter(Mandatory = $true)]
    [string] $sqlServerName,

    [Parameter(Mandatory = $true)]
    [string] $databasesObject,

    [Parameter(Mandatory = $true)]
    [string] $databricksToken,

    [Parameter(Mandatory = $true)]
    [string] $databricksWorkspaceUrl,

    [Parameter(Mandatory = $true)]
    [string] $dataLakeStorageAccountName,

    [Parameter(Mandatory = $true)]
    [string] $functionAppServicePrincipalId,

    [Parameter(Mandatory = $true)]
    [string] $functionAppMasterKey,

    [Parameter(Mandatory = $true)]
    [string] $functionAppURL,

    [Parameter(Mandatory = $false)]
    [string] $databricksApplicationId,

    [Parameter(Mandatory = $false)]
    [string] $databricksServicePrincipalId,

    [Parameter(Mandatory = $false)]
    [string] $databricksApplicationKey,

    [Parameter(Mandatory = $false)]
    [System.ObsoleteAttribute('No longer used as the token is generated at runtime')]
    [string] $databricksAadToken,

    [Parameter(Mandatory = $true)]
    [string] $azureADGroupId_keyVaultAdministrator,

    [Parameter(Mandatory = $false)]
    [string] $automationAccountPrincipalId,

    [Parameter(Mandatory = $false)]
    [string] $synapseWorkspaceName,

    [Parameter(Mandatory = $false)]
    [string] $synapseSQLPoolName,

    [Parameter(Mandatory = $false)]
    [string] $synapseStorageAccountName,

    [Parameter(Mandatory = $false)]
    [string] $synapseStorageAccountContainer
)

Set-StrictMode -Version "Latest"
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "./functions/adp.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/keyvault.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/azuread.psm1") -Force -Verbose:$false
Import-Module -Name 'DatabricksPS' -RequiredVersion '1.6.2.0' -Force -Verbose:$false

$Context = Initialize-ADPContext -parameters $PSBoundParameters -configFilePath (Join-Path $PSScriptRoot $ConfigFile)
$diagnostics = ConvertFrom-JsonToHash -Object $diagnosticsObject
$databases = ConvertFrom-JsonToHash -Object $databasesObject
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
        ## KeyVault
        ###############################################################################
        # Azure Databricks Service Principal accesses the KeyVault when adding a KeyVault backed secret scope
        $databricksServiceServicePrincipal = Get-AzADServicePrincipal -ApplicationId "2ff814a6-3304-4ab8-85cb-cd0e6f879c1d"
        $readerObjectIds = @($dataFactoryPrincipalId, $functionAppServicePrincipalId, $databricksServicePrincipalId, $databricksServiceServicePrincipal.Id)
        if ([string]::IsNullOrWhiteSpace($automationAccountPrincipalId)) {
            Write-Warning "automationAccountPrincipalId is null or empty. Correct this by adding 'automationAccountPrincipalId' into $ConfigFile and re-run or the access policy for the operational KeyVault wont be there for the Automation Account. See documentation for more instructions."
        }
        else {
            $readerObjectIds += $automationAccountPrincipalId
        }

        $deployerAzureAdObjectId = Get-CurrentUserAzureAdObjectId
        $keyVaultParams = Get-Params -ConfigKey 'operationalSecretsKeyVault' -Context $Context -Diagnostics $diagnostics -Purpose "Operational secrets" -With @{
            "akvName"                    = Get-ResourceName -context $Context -resourceCode "KV" -suffix "003";
            "bypassNetworkDefaultAction" = "AzureServices" # Needed for Key Vault secret scope per https://cloudarchitected.com/2019/02/network-isolation-for-azure-databricks/#Key_Vault-backed_secret_scopes
            "networkDefaultAction"       = "Deny"
            "accessPolicy_adminIds"      = @($deployerAzureAdObjectId, $azureADGroupId_keyVaultAdministrator);
            "accessPolicy_readIds"       = $readerObjectIds;
        }
        if (-not $keyVaultParams.ContainsKey('subnetIdArray')) { $keyVaultParams.Add('subnetIdArray', @()) }
        # Add Default Subnets at the beginning of the array
        $keyVaultParams['subnetIdArray'] = @($databricksNetwork.subnetDBRPublicResourceId, $generalNetwork.subnetVMResourceId, $generalNetwork.subnetWebAppResourceId) + $keyVaultParams['subnetIdArray']

        $keyVault = Invoke-ARM -context $Context -template "keyVault" -resourceGroupName $Context.resourceGroupNames.security -parameters $keyVaultParams
        $keyVaultName = $keyVault.keyVaultName.value
        $keyVaultResourceId = $keyVault.keyVaultResourceId.value
        $keyVaultResourceGroupName = $Context.resourceGroupNames.security
        $keyVaultUri = $keyVault.keyVaultUri.value
        Publish-Variables -vars @{"keyVaultName" = $keyVaultName; "keyVaultResourceGroupName" = $keyVaultResourceGroupName; }

        Invoke-WithTemporaryKeyVaultFirewallAllowance -ipToAllow (Get-CurrentIP) -keyVaultName $keyVaultName -resourceGroup $keyVaultResourceGroupName `
            -codeToExecute `
        {

            # Pre-emptively adding these to Key Vault - they get configured in SQL later
            $databricksSqlUsername = $Context.sqlUsernames.databricks
            $databricksSqlPassword = Get-OrSetKeyVaultGeneratedSecret -keyVaultName $keyVaultName -secretName "databricksSqlPassword" `
                -generator { Get-RandomPassword }

            $secrets = @(
                @{
                    "secretName"  = "databricksSqlPassword";
                    "secretValue" = ConvertFrom-SecureString -AsPlainText -SecureString $databricksSqlPassword;
                };
                @{
                    "secretName"  = "databricksToken";
                    "secretValue" = $databricksToken;
                };
                if ($databricksApplicationKey) {
                    @{
                        "secretName"  = "databricksApplicationKey";
                        "secretValue" = $databricksApplicationKey;
                    };
                }
                @{
                    "secretName"  = "functionAppPowershellMasterKey";
                    "secretValue" = $functionAppMasterKey;
                };
                # Below items are not really secrets, but are currently needed by our Databricks code
                # Todo: Configure non-secrets into Databricks separate to this
                @{
                    "secretName"  = "sqlDatabaseConnectionStringConfig";
                    "secretValue" = ("Server=tcp:" + $sqlServerName + ".database.windows.net,1433;Database=" + $databases.Config + ";Trusted_Connection=False;Encrypt=True");
                };
                @{
                    "secretName"  = "sqlDatabaseConnectionStringStage";
                    "secretValue" = ("Server=tcp:" + $sqlServerName + ".database.windows.net,1433;Database=" + $databases.Stage + ";Trusted_Connection=False;Encrypt=True");
                };
                @{
                    "secretName"  = "sqlServerFQDN";
                    "secretValue" = "$sqlServerName.database.windows.net";
                };
                @{
                    "secretName"  = "databricksSqlUsername";
                    "secretValue" = $databricksSqlUsername;
                };
                @{
                    "secretName"  = "sqlDatabaseNameStage";
                    "secretValue" = $databases.Stage;
                };
                @{
                    "secretName"  = "sqlDatabaseNameConfig";
                    "secretValue" = $databases.Config;
                };
                @{
                    "secretName"  = "azureTenantID";
                    "secretValue" = $TenantId;
                };
                @{
                    "secretName"  = "storageAccountDataLake";
                    "secretValue" = $dataLakeStorageAccountName;
                };
                @{
                    "secretName"  = "functionAppBaseURL";
                    "secretValue" = "https://$functionAppURL";
                };
                if ($databricksApplicationId) {
                    @{
                        "secretName"  = "databricksApplicationID";
                        "secretValue" = $databricksApplicationId;
                    };
                }
                if ($databricksServicePrincipalId) {
                    @{
                        "secretName"  = "databricksServicePrincipalID";
                        "secretValue" = $databricksServicePrincipalId;
                    };
                }
                if ($synapseWorkspaceName) {
                    @{
                        "secretName"  = "synapseConnectionStringSqlPool";
                        "secretValue" = ("Server=tcp:" + $synapseWorkspaceName + ".sql.azuresynapse.net,1433;Initial Catalog=" + $synapseSQLPoolName + ";TrustServerCertificate=False;Encrypt=True");
                    };
                    @{
                        "secretName"  = "synapseFQDN";
                        "secretValue" = ($synapseWorkspaceName + ".sql.azuresynapse.net");
                    };
                    @{
                        "secretName"  = "synapseSQLPool";
                        "secretValue" = $synapseSQLPoolName;
                    };
                    @{
                        "secretName"  = "synapseStorageAccountDataLake";
                        "secretValue" = $synapseStorageAccountName;
                    };
                    @{
                        "secretName"  = "synapseStorageAccountContainer";
                        "secretValue" = $synapseStorageAccountContainer;
                    };
                }
            )

            $secrets | Foreach-Object {
                $currentValue = Get-OptionalAzKeyVaultSecretValue -VaultName $keyVaultName -Name $_.secretName
                if ($currentValue -ne $_.secretValue) {
                    Write-Host "Setting Key Vault value for $($_.secretName) in $keyVaultName"
                    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $_.secretName -SecretValue (ConvertTo-SecureString -AsPlainText -Force -String $_.secretValue) | Out-Null
                }
                else {
                    Write-Host "Existing Key Vault value for $($_.secretName) OK"
                }
            }
        }

        ###############################################################################
        ## Databricks - Attach keyvault to secret scope
        ###############################################################################

        Write-Host "Adding keyvault '$keyVaultName' as a secret scope called 'datalakeconfig' within databricks"

        Write-Verbose "Getting Token for DataBricks"
        $databricksAadToken = Get-AzAccessToken -ResourceUrl "2ff814a6-3304-4ab8-85cb-cd0e6f879c1d" -ErrorAction 'Stop' | Select-Object -ExpandProperty Token
        Set-DatabricksEnvironment -ApiRootUrl $databricksWorkspaceUrl -AccessToken $databricksAadToken -Verbose:$false

        try {
            $existingScope = Get-DatabricksSecretScope -Verbose:$false | Where-Object { $_ -and $_.name -eq "datalakeconfig" } | Select-Object -First 1
            if (-not $existingScope) {
                Add-DatabricksSecretScope -ScopeName "datalakeconfig" -AzureKeyVaultResourceID $keyVaultResourceId -AzureKeyVaultDNS $keyVaultUri -InitialManagePrincipal "users" -Verbose:$false
            }
        }
        catch {
            # https://github.com/MicrosoftDocs/azure-docs/issues/65000
            Write-Warning "⚠️  Can't add KeyVault backed Databricks secret scope; not yet supported to run this using a service principal. Please execute the following with a suitably authorised account:`r`n > `$databricksAadToken = Get-AzAccessToken -ResourceUrl ""2ff814a6-3304-4ab8-85cb-cd0e6f879c1d"" | Select-Object -ExpandProperty Token`r`n > Set-DatabricksEnvironment -ApiRootUrl ""$databricksWorkspaceUrl"" -AccessToken `$databricksAadToken`r`n > Add-DatabricksSecretScope -ScopeName ""datalakeconfig"" -AzureKeyVaultResourceID ""$keyVaultResourceId"" -AzureKeyVaultDNS ""$keyVaultUri""`r`nError: $_"
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
