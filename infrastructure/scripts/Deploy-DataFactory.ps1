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
    [string] $generalNetworkObject,

    [Parameter(Mandatory = $true)]
    [string] $deploymentKeyVaultName,

    [Parameter(Mandatory = $true)]
    [string] $codeStorageAccountName,

    [Parameter(Mandatory = $true)]
    [string] $codeStorageResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $dataLakeResourceId,

    [Parameter(Mandatory = $true)]
    [string] $sqlServerResourceId,

    [Parameter(Mandatory = $false)]
    [string] $azureADGroupId_dataFactoryContributor,

    [Parameter(Mandatory = $false)]
    [string] $deploySHIR = 'true'
)

Set-StrictMode -Version "Latest"
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "./functions/adp.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/storage.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/keyvault.psm1") -Force -Verbose:$false

$Context = Initialize-ADPContext -parameters $PSBoundParameters -configFilePath (Join-Path $PSScriptRoot $ConfigFile)
$diagnostics = ConvertFrom-JsonToHash -Object $diagnosticsObject
$generalNetwork = ConvertFrom-JsonToHash -Object $generalNetworkObject

[bool]$booldeploySHIR = Convert-ToBoolean $deploySHIR # must be string to support AzDo pipelines, converted to boolen in function below.

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
        ## Data Factory
        ###############################################################################

        $datafactoryParams = Get-Params -context $Context -diagnostics $diagnostics -configKey "datafactory" -with @{
            "adfName"             = Get-ResourceName -context $Context -resourceCode "ADF" -suffix "001";
            "integrationRuntimes" = @("ADP");
        }

        $CurrentADF = Get-AzDataFactoryV2 -ResourceGroupName $Context.resourceGroupNames.data -Name $datafactoryParams.adfName -ErrorAction 'SilentlyContinue'
        if ($null -ne $CurrentADF) {
            # The RepoConfiguration includes the lastCommitId but that's dynamic, so we need to inject that into the
            # ARM template from the current information in Azure.
            if (
                ($null -ne $CurrentADF.RepoConfiguration) `
                    -and ($null -ne $CurrentADF.RepoConfiguration.LastCommitId) `
                    -and ($null -ne $datafactoryParams['repoConfiguration'])
            ) {
                Write-Verbose "Using lastCommitId of '$($CurrentADF.RepoConfiguration.LastCommitId)' for the Data Factory Repo Configuration"
                $datafactoryParams['repoConfiguration']['lastCommitId'] = $CurrentADF.RepoConfiguration.LastCommitId
            }
        }

        $dataFactory = Invoke-ARM -context $Context -template "dataFactory" -resourceGroupName $Context.resourceGroupNames.data -parameters $datafactoryParams

        Publish-Variables -vars @{
            "dataFactoryPrincipalId" = $dataFactory.dataFactoryPrincipalId.Value
            "dataFactoryResourceId"  = $dataFactory.dataFactoryResourceId.Value
        }

        $integrationRuntimeKey = $dataFactory.integrationRuntimesResourceIdArray.Value[0].resourceId;

        ###############################################################################
        ## Data Factory - Role Assignments
        ###############################################################################

        # Give Data Factory service principal read/write access to the data lake
        $datafactoryRoleParams = Get-Params -context $Context -with @{
            "principalId"     = $dataFactory.dataFactoryPrincipalId.Value;
            "builtInRoleType" = "Storage Blob Data Contributor";
            "resourceId"      = $dataLakeResourceId;
            "roleGuid"        = "guidDataFactorytoDatalake"; # To keep idempotent, dont change this string after first run
        }
        Invoke-ARM -context $Context -template "roleAssignment" -resourceGroupName $Context.resourceGroupNames.data -parameters $datafactoryRoleParams

        # Give Data Factory service principal contributor access to the SQL Server instance
        $datafactoryRoleParams = Get-Params -context $Context -with @{
            "principalId"     = $dataFactory.dataFactoryPrincipalId.Value;
            "builtInRoleType" = "SQL DB Contributor";
            "resourceId"      = $sqlServerResourceId;
            "roleGuid"        = "guidDataFactorytoSqlServer"; # To keep idempotent, dont change this string after first run
        }
        Invoke-ARM -context $Context -template "roleAssignment" -resourceGroupName $Context.resourceGroupNames.data -parameters $datafactoryRoleParams

        # Give Azure AD Group contributor rights over Azure Data Factory
        if ($azureADGroupId_dataFactoryContributor) {
            $datafactoryRoleParams = Get-Params -context $Context -with @{
                "principalId"     = $azureADGroupId_dataFactoryContributor;
                "builtInRoleType" = "Data Factory Contributor";
                "resourceId"      = $dataFactory.dataFactoryResourceId.Value;
                "roleGuid"        = "guidAadGrouptoDataFactory"; # To keep idempotent, dont change this string after first run
            }
            Invoke-ARM -context $Context -template "roleAssignment" -resourceGroupName $Context.resourceGroupNames.data -parameters $datafactoryRoleParams
        }
        else {
            Write-Warning "⚠️  Skipping role assignment for Azure Data Factory Contributor, this is likely because of no privileges on the Azure AD tenancy $TenantId; follow documentation to manually configure this otherwise access will be denied."
        }


        ###############################################################################
        ## Self-Hosted Integration Runtime Virtual Machines
        ###############################################################################
        if ($Context.create.virtualMachine) {

            if ($booldeploySHIR) {

            
                $availabilitySetName = Get-ResourceName -context $Context -resourceCode "AVS" -suffix "001"

                # If VMs exist then start them otherwise the deployment will fail when executing VM extensions
                $availabilitySetExists = Get-AzAvailabilitySet -Name $availabilitySetName -ResourceGroupName $Context.resourceGroupNames.admin -ErrorAction SilentlyContinue
                if ($availabilitySetExists -and $availabilitySetExists.VirtualMachinesReferences.Count -gt 0) {
                    $vmsOff = Get-AzVm -ResourceGroupName $Context.resourceGroupNames.admin -Status | Where-Object { $_.PowerState -eq "VM deallocated" }
                    $vmsOff | ForEach-Object -Parallel {
                        Write-Host "Starting Virtual Machine $($_.Name)"
                        Start-AzVM -Name $_.Name -ResourceGroupName $_.ResourceGroupName
                    }
                    if (Get-AzVm -ResourceGroupName $Context.resourceGroupNames.admin -Status | Where-Object { $_.PowerState -ne "VM running" }) {
                        do {
                            Write-Host "Waiting for the virtual machines to start...".
                            Start-Sleep 60
                        } until (Get-AzVm -ResourceGroupName $Context.resourceGroupNames.admin -Status | Where-Object { $_.PowerState -eq "VM running" })
                    }
                }
                else {
                    Write-Verbose "There are no VMs in the availability set."
                }

                # Upload PowerShell scripts to code storage
                $codeStorageContext = Get-StorageContext -Name $codeStorageAccountName -ResourceGroupName $codeStorageResourceGroupName
                Get-ChildItem (Join-Path $PSScriptRoot "code/scripts") -Filter *.ps1 | ForEach-Object {
                    Write-Host "Uploading $($_.Name) to $codeStorageAccountName/code"
                    Set-AzStorageBlobContent -File $_.FullName -Container "code" -Blob $_.Name -Context $codeStorageContext -Force -Properties @{"ContentType" = "text/plain" } | Out-Null
                }
                $container = Get-AzStorageContainer -Name "code" -Context $codeStorageContext
                $sas = $container | New-AzStorageContainerSASToken -Permission "rl" -StartTime (Get-Date).ToUniversalTime().AddMinutes(-5) -ExpiryTime (Get-Date).ToUniversalTime().AddHours(2);

                # Need to set a secret value and generate if it doesn't already exist - so we don't create another version of the secret every time we (re)deploy
                Write-Host "Getting/generating vmServerAdminPassword secret"
                $vmServerAdminPassword = Get-OrSetKeyVaultGeneratedSecret -keyVaultName $deploymentKeyVaultName -secretName "vmServerAdminPassword" `
                    -generator { Get-RandomPassword }

                $adminUsername = $Context.CompanyCode + "_AzureAdmin"
                if ($Context.EnvironmentCode -eq 'PRD') {
                    # Production environment is using the wrong admin username so we hardcode here
                    $adminUsername = 'AUAZECORP_AzureAdmin'
                }

                # Deploy the virtual machines
                $virtualMachineParams = Get-Params -context $Context -configKey "virtualMachine" -diagnostics $diagnostics -purpose "Data Factory SHIR" -with @{
                    "adfIntegrationRuntimeKey" = $integrationRuntimeKey;
                    "subnetResourceId"         = $generalNetwork.subnetVMResourceId;
                    "adminUsername"            = $adminUsername;
                    "adminPassword"            = $vmServerAdminPassword;
                    "availabilitySetName"      = $availabilitySetName;
                    "scriptBlobContainer"      = $container.BlobContainerClient.Uri.AbsoluteUri;
                    "scriptBlobSASToken"       = $sas.ToString();
                    "scriptName"               = "Install-SelfHostedIR.ps1";
                    "OSType"                   = "Windows";
                }
                Invoke-ARM -context $Context -template "virtualMachine.SHIRInstall" -resourceGroupName $Context.resourceGroupNames.admin -parameters $virtualMachineParams
            }
            else {
                Write-Host "Skipping Azure Data Factory Integration Runtime VM configuration as requested by the pipeline."
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
