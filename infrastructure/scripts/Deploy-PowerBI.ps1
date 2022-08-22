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

    [Parameter(Mandatory = $false)]
    [string] $deployPowerBi = 'true'
)

Set-StrictMode -Version "Latest"
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "./functions/adp.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/keyvault.psm1") -Force -Verbose:$false

$Context = Initialize-ADPContext -parameters $PSBoundParameters -configFilePath (Join-Path $PSScriptRoot $ConfigFile)
$diagnostics = ConvertFrom-JsonToHash -Object $diagnosticsObject
$generalNetwork = ConvertFrom-JsonToHash -Object $generalNetworkObject

[bool]$booldeployPowerBi = Convert-ToBoolean $deployPowerBi # must be string to support AzDo pipelines, converted to boolen in function below.

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
        ## PowerBI Data Gateway Virtual Machines
        ###############################################################################
        if ($Context.create.virtualMachinePowerBiGateway) {

            if ($booldeployPowerBi) {
           
                $availabilitySetName = Get-ResourceName -context $Context -resourceCode "AVS" -suffix "002"

                # Need to set a secret value and generate if it doesn't already exist - so we don't create another version of the secret every time we (re)deploy
                Write-Host "Getting/generating vmServerAdminPassword secret"
                $vmServerAdminPassword = Get-OrSetKeyVaultGeneratedSecret -keyVaultName $deploymentKeyVaultName -secretName "vmServerAdminPassword" `
                    -generator { Get-RandomPassword }

                $adminUsername = $Context.CompanyCode + "_AzureAdmin"
                if ($Context.EnvironmentCode -eq 'PRD') {
                    # Production environment is using the wrong admin username so we hardcode here
                    $adminUsername = 'AUAZECORP_AzureAdmin'
                }

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

                # Deploy the virtual machines
                # Currently the PowerBI Gateway Installation is manual due to installer not being automatable without needing god-mode like permissions! 
                # As result, this feautre is not developed. See post-deploy.md in repo for steps to complete.
                $virtualMachineParams = Get-Params -context $Context -configKey "virtualMachinePowerBiGateway" -diagnostics $diagnostics -purpose "PowerBI Gateway" -with @{
                    "subnetResourceId"    = $generalNetwork.subnetVMResourceId;
                    "adminUsername"       = $adminUsername;
                    "adminPassword"       = $vmServerAdminPassword;
                    "availabilitySetName" = $availabilitySetName;
                    "OSType"              = "Windows";
                }
                Invoke-ARM -context $Context -template "virtualMachine.PowerBiGatewayInstall" -resourceGroupName $Context.resourceGroupNames.admin -parameters $virtualMachineParams
            }
            else {
                Write-Host "Skipping PowerBi Gateway VM configuration as requested by the pipeline."
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
