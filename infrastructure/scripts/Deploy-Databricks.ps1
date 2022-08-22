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

    [Parameter(Mandatory = $true)]
    [string] $databricksNetworkObject,

    [Parameter(Mandatory = $false)]
    [string] $ConfigFile = "config.$($EnvironmentCode.ToLower()).json",

    [Parameter(Mandatory = $true)]
    [string] $diagnosticsObject,

    [Parameter(Mandatory = $true)]
    [string] $deploymentKeyVaultName,

    [Parameter(Mandatory = $true)]
    [string] $DatabricksAadToken,

    [Parameter(Mandatory = $true)]
    [string] $AzureManagementApiAadToken,

    [Parameter(Mandatory = $true)]
    [string] $sqlServerResourceId,

    [Parameter(Mandatory = $true)]
    [string] $dataLakeResourceId,

    [Parameter(Mandatory = $false)]
    [string] $azureADGroupId_databricksContributor,

    [Parameter(Mandatory = $false)]
    [string] $synapseStorageAccountID
)

Set-StrictMode -Version "Latest"
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "./functions/adp.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/keyvault.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/databricks.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/azuread.psm1") -Force -Verbose:$false
Import-Module -Name 'DatabricksPS' -RequiredVersion '1.6.2.0' -Force -Verbose:$false

$Context = Initialize-ADPContext -parameters $PSBoundParameters -configFilePath (Join-Path $PSScriptRoot $ConfigFile)
$diagnostics = ConvertFrom-JsonToHash -Object $diagnosticsObject
$databricksNetwork = ConvertFrom-JsonToHash -Object $databricksNetworkObject

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
        ## Databricks
        ###############################################################################

        $subNetName_DBRPublic = $databricksNetwork.subnetDBRPublicResourceId.replace($databricksNetwork.vNetResourceId, "").replace("/subnets/", "")
        $subNetName_DBRPrivate = $databricksNetwork.subnetDBRPrivateResourceId.replace($databricksNetwork.vNetResourceId, "").replace("/subnets/", "")

        $dbrName = Get-ResourceName -context $Context -resourceCode "DBRK" -suffix "001"
        $databricksParams = Get-Params -context $Context -configKey "databricks" -with @{
            "dbrName"                  = $dbrName;
            "vnetResourceId"           = $databricksNetwork.vNetResourceId;
            "subNetName_DBRPublic"     = $subNetName_DBRPublic;
            "subNetName_DBRPrivate"    = $subNetName_DBRPrivate;
            "managedResourceGroupName" = $Context.resourceGroupNames.databricks;
        }
        $databricksArmOutputs = Invoke-ARM -context $Context -template "databricks" -resourceGroupName $Context.resourceGroupNames.data -parameters $databricksParams
        $databricksWorkspaceUrl = $databricksArmOutputs.databricksWorkspaceUrl.value
        $databricksWorkspaceName = $databricksArmOutputs.databricksWorkspaceName.value

        ###############################################################################
        ## Databricks token
        ###############################################################################

        [ScriptBlock] $createNewToken = {
            $databricksWorkspaceResourceId = $databricksArmOutputs.databricksResourceId.value
            $databricksWorkspaceUrl = $databricksWorkspaceUrl

            $newDatabricksTokenParams = @{
                DatabricksAadToken            = $DatabricksAadToken;
                ManagementAadToken            = $AzureManagementApiAadToken;
                DatabricksWorkspaceUrl        = $databricksWorkspaceUrl;
                DatabricksWorkspaceResourceId = $databricksWorkspaceResourceId;
            }

            New-DatabricksToken @newDatabricksTokenParams
        }

        $currentValue = Get-OptionalAzKeyVaultSecretValue -VaultName $deploymentKeyVaultName -Name "DatabricksWorkspaceUrl"
        if ($currentValue -ne $databricksWorkspaceUrl) {
            Write-Host "Setting Key Vault value for 'DatabricksWorkspaceUrl' in $deploymentKeyVaultName to $databricksWorkspaceUrl"
            Set-AzKeyVaultSecret -VaultName $deploymentKeyVaultName -Name "DatabricksWorkspaceUrl" -SecretValue (ConvertTo-SecureString -AsPlainText -Force -String $databricksWorkspaceUrl) | Out-Null
            $databricksToken = & $createNewToken
            Set-AzKeyVaultSecret -VaultName $deploymentKeyVaultName -Name "DatabricksToken" -SecretValue (ConvertTo-SecureString -AsPlainText -Force -String $databricksToken) | Out-Null
        }
        else {
            $databricksToken = Get-OrSetKeyVaultGeneratedSecret -keyVaultName $deploymentKeyVaultName -secretName 'DatabricksToken' -generator $createNewToken | ConvertFrom-SecureString -AsPlainText
        }

        Publish-Variables -vars @{ "databricksToken" = $databricksToken; } -isSecret
        Publish-Variables -vars @{ "databricksWorkspaceUrl" = $databricksWorkspaceUrl; }

        ###############################################################################
        ## Databricks - Azure AD Application Registration
        ###############################################################################

        $monthsMaxCredentialLife = $Context.databricksAADAppRegistration.maxCredentialExpiryInMonths;
        $monthsMinCredentialLife = $Context.databricksAADAppRegistration.minCredentialExpiryInMonths;

        if ($Context.deployAzureADResources) {
            Write-Host "$(Get-Date -Format FileDateTimeUniversal) Executing '$dbrName' Azure AD application creation."

            $AzADApplicationRegistration = Get-AzADApplication -DisplayName $dbrName -ErrorAction SilentlyContinue
            $AzADServicePrincipal = Get-AzADServicePrincipal -DisplayName $dbrName -ErrorAction SilentlyContinue
            if (-not($AzADApplicationRegistration)) {
                $AzADApplicationRegistration = New-AzADApplication -DisplayName $dbrName -HomePage "http://$($dbrName)"
                $AzADServicePrincipal = New-AzADServicePrincipal -ApplicationId $AzADApplicationRegistration.ApplicationId -SkipAssignment
            }

            Publish-Variables -vars @{
                "databricksApplicationId"      = $AzADApplicationRegistration.ApplicationId.Guid;
                "databricksServicePrincipalId" = $AzADServicePrincipal.Id
            }

            # Get the latest credential for the Application Registration
            #
            # Unfortunately the underlying .NET class for this API returns the EndDate as a string (Why?!?) not a Date object which
            # means we can't reliably do sorting as it may be locale dependant (e.g. M/d/Y can't alpha sort correctly). Instead we
            # map the array and convert the string into a DateFormat, which is then sortable. This does depend on the underlying
            # .NET class to use the same default datetime formatting
            $LatestAppCred = Get-AzADAppCredential -ApplicationId $AzADApplicationRegistration.ApplicationId.Guid |
            ForEach-Object { Write-Output ([DateTime]::Parse($_.EndDate)) } |
            Sort-Object -Descending |
            Select-Object -First 1

            if (-not($LatestAppCred) -or ($LatestAppCred -lt (Get-Date).AddMonths($monthsMinCredentialLife))) {
                if ($LatestAppCred) { Write-Host "Azure AD Application will expire" }
                Write-Host "Creating new Azure AD application credential for Databricks."

                $dbrAppPassword = Get-RandomPassword
                New-AzADAppCredential -ApplicationId $AzADApplicationRegistration.ApplicationId -Password $dbrAppPassword -StartDate (Get-Date).AddMinutes(-5).ToUniversalTime() -EndDate (Get-Date).AddMonths($monthsMaxCredentialLife).ToUniversalTime()

                #Generate a new version of the secret if a new app credential is required
                Set-AzKeyVaultSecret -VaultName $deploymentKeyVaultName -SecretName 'databricksApplicationKey' `
                    -SecretValue $dbrAppPassword | Out-Null

                Publish-Variables -vars @{ "databricksApplicationKey" = $dbrAppPassword } -isSecret
            }
            else {
                Write-Host ($dbrName + " Azure AD application credential exists and is valid for at least " + $monthsMinCredentialLife + " more months.")

                # If we're not creating anything, grab the existing secret from Deployment KeyVault and publish it so we can save it in the Application KeyVault later.
                $secret = Get-AzKeyVaultSecret -VaultName $deploymentKeyVaultName -Name 'databricksApplicationKey'
                $secretValueText = $secret | Select-Object -ExpandProperty SecretValue | ConvertFrom-SecureString -AsPlainText
                Publish-Variables -vars @{ "databricksApplicationKey" = $secretValueText } -isSecret
            }

            Write-Host -ForegroundColor Green "`r`n✔️  $(Get-Date -Format FileDateTimeUniversal) '$dbrName'  Azure AD application created successfully.`r`n"

            ###############################################################################
            ## Databricks - Role Assignments to grant Databricks user access to call SQL and Data Factory
            ###############################################################################

            # Give Databricks service principal contributor level access to SQL server
            $datafactoryRoleParams = Get-Params -context $Context -with @{
                "principalId"     = $AzADServicePrincipal.Id;
                "builtInRoleType" = "SQL DB Contributor";
                "resourceId"      = $sqlServerResourceId;
                "roleGuid"        = "guidDatabrickstoSqlServer"; # To keep idempotent, dont change this string after first run
            }
            Invoke-ARM -context $Context -template "roleAssignment" -resourceGroupName $Context.resourceGroupNames.data -parameters $datafactoryRoleParams

            # Give Databricks service principal read/write access to the data lake
            $datafactoryRoleParams = Get-Params -context $Context -with @{
                "principalId"     = $AzADServicePrincipal.Id;
                "builtInRoleType" = "Storage Blob Data Contributor";
                "resourceId"      = $dataLakeResourceId;
                "roleGuid"        = "guidDatabrickstoDatalake"; # To keep idempotent, dont change this string after first run
            }
            Invoke-ARM -context $Context -template "roleAssignment" -resourceGroupName $Context.resourceGroupNames.data -parameters $datafactoryRoleParams

            if ($Context.create.synapse) {
                # Give Databricks service principal read/write access to the Synapse storage account
                $synapseRoleParams = Get-Params -context $Context -with @{
                    "principalId"     = $AzADServicePrincipal.Id;
                    "builtInRoleType" = "Storage Blob Data Contributor";
                    "resourceId"      = $synapseStorageAccountID;
                    "roleGuid"        = "guidDatabrickstoSynapseStorage"; # To keep idempotent, dont change this string after first run
                }
                Invoke-ARM -context $Context -template "roleAssignment" -resourceGroupName $Context.resourceGroupNames.data -parameters $synapseRoleParams
            }
        }
        else {
            Write-Warning "⚠️  Skipping creation of Azure AD Service Principal for Databricks due to no permission on the Azure AD tenancy $TenantId; follow documentation to manually configure this otherwise databricks will be unable to access SQL and the Data lake."

            Publish-Variables -vars @{
                "databricksApplicationId"      = "";
                "databricksServicePrincipalId" = "";
            }
        }

        ###############################################################################
        ## Databricks - Role Assignment for contributors Azure AD Group
        ###############################################################################

        # Give the Azure AD Group Contributor access to the Databricks workspace
        if ($azureADGroupId_databricksContributor) {
            $datafactoryRoleParams = Get-Params -context $Context -with @{
                "principalId"     = $azureADGroupId_databricksContributor;
                "builtInRoleType" = "Contributor";
                "resourceId"      = $databricksArmOutputs.databricksResourceId.value;
                "roleGuid"        = "guidAadGrouptoDatabricks"; # To keep idempotent, dont change this string after first run
            }
            Invoke-ARM -context $Context -template "roleAssignment" -resourceGroupName $Context.resourceGroupNames.data -parameters $datafactoryRoleParams
        }
        else {
            Write-Warning "⚠️  Skipping role assignment for Databricks Contributors, this is likely because of no privileges on the Azure AD tenancy $TenantId; follow documentation to manually configure this otherwise access will be denied."
        }

        ###############################################################################
        ## Databricks - Configure Databricks
        ###############################################################################

        Write-Host "$(Get-Date -Format FileDateTimeUniversal) Executing Databricks clusters creation."

        # Connect to Databricks
        Set-DatabricksEnvironment -ApiRootUrl $databricksWorkspaceUrl -AccessToken $databricksToken -Verbose:$false
        Write-Verbose ((Get-Date -f "hh:mm:ss tt") + " - " + "Connected to Databricks workspace $databricksWorkspaceName ($databricksWorkspaceUrl)")

        # Default varaible for Databricks Cluster
        $minWorkers = $Context.databricksClusters.minWorkers
        $maxWorkers = $Context.databricksClusters.maxWorkers
        $terminationDurationMinutes = $Context.databricksClusters.terminationDurationMinutes
        $pythonVersion = "3 (3.5)";
        $sparkVersion = $Context.databricksClusters.sparkVersion;
        $libraries = @(
            @{maven = @{coordinates = "com.microsoft.azure:spark-mssql-connector:1.0.1" } },
            @{pypi = @{package = "rapidfuzz==1.1.0" } }
        )
        $standardSparkConfig = $Context.databricksClusters.standardClusterSparkConfig
        $highConcurrencySparkConfig = $Context.databricksClusters.highConcurrencyClusterSparkConfig

        # Create the standard cluster if there isn't one
        if ($Context.databricksClusters.deployStandardSku) {
            #Check is sku has value. If null then this skips.
            $databricksClusterName = $databricksWorkspaceName + $Context.Delimiter + "CLU" + $Context.Delimiter + "Standard"

            # Gets or creates the DBR cluster.
            $databricksCluster = Get-OrNewAndUpdateDatabricksCluster -Name $databricksClusterName `
                -autoScale $true `
                -nodeSize $Context.databricksClusters.deployStandardSku `
                -clusterType "Standard" `
                -minWorkers $minWorkers `
                -maxWorkers $maxWorkers `
                -terminationDurationMinutes $terminationDurationMinutes `
                -pythonVersion $pythonVersion `
                -sparkVersion $sparkVersion `
                -sparkConfig $standardSparkConfig

            $databricksClusterId = $databricksCluster.cluster_id

            #Publish the Databricks standard cluster Id to pre-populate the SQL configuration data
            Get-OrSetKeyVaultSecret -keyVaultName $deploymentKeyVaultName -secretName "databricksStandardClusterId" -secretValue $databricksClusterId | Out-Null

            # Install the libraries
            Add-DatabricksClusterLibraries -ClusterID $databricksClusterId -Libraries $libraries -Verbose:$false

            # Pin the cluster
            Pin-DatabricksCluster -ClusterID $databricksClusterId

            Write-Host -ForegroundColor Green "`r`n✔️  $(Get-Date -Format FileDateTimeUniversal) '$databricksClusterName' databricks cluster created successfully.`r`n"
        }

        # Create the high concurrency cluster if there isn't one
        if ($Context.databricksClusters.deployHighConcurrencySku) {
            #Check is sku has value. If null then this skips.
            $databricksClusterName = $databricksWorkspaceName + $Context.Delimiter + "CLU" + $Context.Delimiter + "HighConcurrency"

            # Gets or creates the DBR cluster.
            $databricksCluster = Get-OrNewAndUpdateDatabricksCluster -Name $databricksClusterName `
                -nodeSize $Context.databricksClusters.deployStandardSku `
                -autoScale $true `
                -clusterType "HighConcurrency" `
                -minWorkers $minWorkers `
                -maxWorkers $maxWorkers `
                -terminationDurationMinutes $terminationDurationMinutes `
                -pythonVersion $pythonVersion `
                -sparkVersion $sparkVersion `
                -sparkConfig $highConcurrencySparkConfig

            $databricksClusterId = $databricksCluster.cluster_id

            # Install the libraries
            Add-DatabricksClusterLibraries -ClusterID $databricksClusterId -Libraries $libraries -Verbose:$false

            # Pin the cluster
            Pin-DatabricksCluster -ClusterID $databricksClusterId

            Write-Host -ForegroundColor Green "`r`n✔️  $(Get-Date -Format FileDateTimeUniversal) '$databricksClusterName' databricks cluster created successfully.`r`n"
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
