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
    [string] $diagnosticsObject
)

Set-StrictMode -Version "Latest"
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "./functions/adp.psm1") -Force -Verbose:$false

$Context = Initialize-ADPContext -parameters $PSBoundParameters -configFilePath (Join-Path $PSScriptRoot $ConfigFile)
$diagnostics = ConvertFrom-JsonToHash -Object $diagnosticsObject

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

        if ($Context.deploySubscriptionResources) {

            ###############################################################################
            ## Azure Security Centre / Azure Defender
            ###############################################################################

            if ($Context.create.asc) {
                $ascParams = Get-Params -context $Context -configKey "azureSecurityCentre" -with @{
                    "integrationName"         = "WDATP";
                    "logAnalyticsWorkspaceId" = $diagnostics.logAnalyticsWorkspaceId;
                }
                Invoke-ARM -context $Context -Location $Location -template "securityCentre" -parameters $ascParams
            }

            ###############################################################################
            ## Azure Policy - Default
            ###############################################################################

            if ($Context.create.policyBasic) {
                $polBasicParams = Get-Params -context $Context -with @{
                    "subscriptionId" = $SubscriptionId;
                    "azureLocation"  = $Location
                    "notScopes"      = @();
                }
                Invoke-ARM -context $Context -Location $Location -template "azurePolicy.basic" -parameters $polBasicParams
            }

            ###############################################################################
            ## Azure Policy - ISM Protected Blueprint
            ###############################################################################

            if ($Context.create.policyISMAustralia) {
                $polISMParams = Get-Params -context $Context -with @{
                    "subscriptionId"          = $SubscriptionId;
                    "azureLocation"           = $Location
                    "notScopes"               = @();
                    "logAnalyticsWorkspaceId" = $diagnostics.logAnalyticsWorkspaceId;
                }
                Invoke-ARM -context $Context -Location $Location -template "azurePolicy.ISMProtectedAustralia" -parameters $polISMParams
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
