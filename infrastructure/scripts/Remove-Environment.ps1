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
    [string] $ConfigFile = "config.$($EnvironmentCode.ToLower()).json"
)

Set-StrictMode -Version "Latest"
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "./functions/adp.psm1") -Force -Verbose:$false

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

        $confirmation = Read-Host "Are you sure you want to proceed with deleting your entire environment (Y/N)"

        if ($confirmation -ne 'Y') {
            exit 1
        }

        $Context.resourceGroupNames.Keys | ForEach-Object -Parallel {

            if ($_ -eq "databricks") {
                return
            }

            $resourceGroupNames = $using:Context.resourceGroupNames
            $resourceGroupName = $resourceGroupNames[$_]

            Write-Host "Removing locks from $resourceGroupName"
            $existingLocks = Get-AzResourceLock -ResourceGroupName $resourceGroupName -AtScope
            $existingLocks | ForEach-Object {
                Remove-AzResourceLock -LockId $_.LockId -Confirm:$false -Force | Out-Null
            }
            Write-Host "Removed locks from $resourceGroupName"
        }

        Write-Host "Purging KeyVaults"
        Remove-AzKeyVault -InRemovedState -VaultName (Get-ResourceName -context $Context -resourceCode "AKV" -suffix "001") -Location $Location -Force -ErrorAction SilentlyContinue
        Remove-AzKeyVault -InRemovedState -VaultName (Get-ResourceName -context $Context -resourceCode "AKV" -suffix "002") -Location $Location -Force -ErrorAction SilentlyContinue

        $Context.resourceGroupNames.Keys | ForEach-Object -Parallel {

            if ($_ -eq "databricks") {
                return
            }

            $resourceGroupNames = $using:Context.resourceGroupNames
            $resourceGroupName = $resourceGroupNames[$_]

            Write-Host "Removing resource group and resources in $resourceGroupName"
            Remove-AzResourceGroup -Name $resourceGroupName -Force -Confirm:$false
            Write-Host "Removed resource group and resources for $resourceGroupName"
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