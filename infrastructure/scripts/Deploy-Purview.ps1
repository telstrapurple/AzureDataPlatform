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
    [string] $deploymentKeyVaultName,

    [Parameter(Mandatory = $true)]
    [string] $codeStorageAccountName,

    [Parameter(Mandatory = $true)]
    [string] $codeStorageResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $generalNetworkObject,

    [Parameter(Mandatory = $false)]
    [string] $deploySHIR = 'true' 
)

Set-StrictMode -Version "Latest"
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "./functions/adp.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/azuread.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/storage.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/keyvault.psm1") -Force -Verbose:$false

$Context = Initialize-ADPContext -parameters $PSBoundParameters -configFilePath (Join-Path $PSScriptRoot $ConfigFile)
$diagnostics = ConvertFrom-JsonToHash -Object $diagnosticsObject
$generalNetwork = ConvertFrom-JsonToHash -Object $generalNetworkObject

[bool]$booldeploySHIR = Convert-ToBoolean $deploySHIR # must be string to support AzDo pipelines, converted to boolen in function below.

if (-not ($Context.create.ContainsKey('purview') -and $Context.create.purview)) {
    Write-Host "'create.purview' is not set to 'true' in the configuration file"
    Exit 0
}

Import-Module -Name 'Az.Purview' -RequiredVersion '0.1.0' -Force -Verbose:$false

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
        ## Purview Account
        ###############################################################################
        $purviewAccountName = Get-ResourceName -context $Context -resourceCode "PVW" -suffix "001"
        $purviewAccountRGName = $Context.resourceGroupNames.data

        $purviewParams = Get-Params -context $Context -configKey "purview" -purpose "Purview" -with @{
            'purviewAccountName' = $purviewAccountName
        }
        $result = Invoke-ARM -context $Context -template "purview" -resourceGroupName $purviewAccountRGName -parameters $purviewParams
        $purviewAccount = Get-AzPurviewAccount -Name $purviewAccountName -ResourceGroupName $purviewAccountRGName

        ###############################################################################
        ## Root Collection Administrator
        ###############################################################################

        Write-Host "Setting Purview Root Collection Administrator"
        $adminAccount = Get-AzADGroupObjectOrDisplayName -displayNameObjectId $Context.azureADGroups.purviewCollectionAdministratorName
        if ($null -eq $adminAccount) {
            Throw "The AD Group specified at 'azureADGroups.purviewCollectionAdministratorName' with value '$($Context.azureADGroups.purviewCollectionAdministratorName)' could not be found in Azure Active Directory"
        }
        # Unfortunately you can't check if an account is already added, so instead we have to always add it.
        # It does not throw an error if the account already exists
        $purviewAccount | Add-AzPurviewAccountRootCollectionAdmin -ObjectId $adminAccount.Id | Out-Null

        ###############################################################################
        ## Self-Hosted Integration Runtime Virtual Machines
        ###############################################################################
        if ($Context.create.ContainsKey('virtualMachinePurview') -and $Context.create.virtualMachinePurview) {
            $SecretName = 'purviewIntegrationKey'
            $secret = Get-AzKeyVaultSecret -VaultName $deploymentKeyVaultName -Name $SecretName -ErrorAction SilentlyContinue
            if ($secret) {

                if ($booldeploySHIR) {
                    $integrationKey = $secret.SecretValue | ConvertFrom-SecureString -AsPlainText

                    $availabilitySetName = Get-ResourceName -context $Context -resourceCode "AVS" -suffix "003"

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
                    $virtualMachineParams = Get-Params -context $Context -configKey "virtualMachinePurview" -diagnostics $diagnostics -purpose "Azure Purview SHIR" -with @{
                        "adfIntegrationRuntimeKey" = $integrationKey;
                        "subnetResourceId"         = $generalNetwork.subnetVMResourceId;
                        "adminUsername"            = $adminUsername;
                        "adminPassword"            = $vmServerAdminPassword;
                        "availabilitySetName"      = $availabilitySetName;
                        "scriptBlobContainer"      = $container.BlobContainerClient.Uri.AbsoluteUri;
                        "scriptBlobSASToken"       = $sas.ToString();
                        "scriptName"               = "Install-SelfHostedIR.ps1";
                        "OSType"                   = "Windows";
                    }
                    Invoke-ARM -context $Context -template "virtualMachine.PurviewSHIRInstall" -resourceGroupName $Context.resourceGroupNames.admin -parameters $virtualMachineParams
                }
                else {
                    Write-Host "Skipping Purview Integration Runtime VM configuration as requested by the pipeline."
                }
            }
        }
        else {
            Write-Host "The Purview Integration Key secret ('$SecretName') is not set in the Key Vault '$deploymentKeyVaultName'. Please follow https://docs.microsoft.com/en-us/azure/purview/manage-integration-runtimes and add the secret to the Key Vault"
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
