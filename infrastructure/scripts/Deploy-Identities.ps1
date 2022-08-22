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
Import-Module (Join-Path $PSScriptRoot "./functions/azuread.psm1") -Force -Verbose:$false

$Context = Initialize-ADPContext -parameters $PSBoundParameters -configFilePath (Join-Path $PSScriptRoot $ConfigFile) -outputTag

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
        # Azure Active Directory
        ##############################################################################
        $azureGraphApiAadToken = Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com' | Select-Object -ExpandProperty Token

        $job = $Context.azureADGroups.Keys | ForEach-Object -AsJob -Parallel {
            Import-Module (Join-Path $using:PSScriptRoot "./functions/adp.psm1") -Force -Verbose:$false
            Import-Module (Join-Path $using:PSScriptRoot "./functions/azuread.psm1") -Force -Verbose:$false
            $hash = $using:Context.azureADGroups
            $value = $hash[$_]
            $name = $_
            $variablesToPublishinLoop = @();
            if ($using:Context.create.azureADGroups) {
                $group = Get-AzADGroupObjectOrDisplayName $value
                if (-not $group) {
                    if (-not (Assert-Guid $value)) {
                        Write-Verbose ($value + " creating Azure AD group in tenancy " + $using:TenantId)
                        $group = Get-OrNewAzureADGroup -azureGraphApiAadToken $using:azureGraphApiAadToken `
                            -displayName $value -isSecurityEnabled `
                            -description "Security Group used by the Azure Data Platform. Usage: $($name.ToLower())"
                        if (-not $group) {
                            throw "Failure to create group $value"
                        }
                        $variablesToPublishinLoop += @{ ("azureADGroupId_" + $name) = $group.id }
                    }
                    else {
                        throw ($value + " Azure AD group Id cannot be found in tenancy " + $using:TenantId + " for key " + $name + ". Make sure the ObjectId Guid is correct.")
                    }
                }
                else {
                    Write-Verbose ($value + " Azure AD group found in tenancy " + $using:TenantId)
                    $variablesToPublishinLoop += @{ ("azureADGroupId_" + $name) = $group.Id }
                }
            }
            else {
                $group = Get-AzADGroupObjectOrDisplayName $value
                if (-not $group) {
                    throw ($value + " is not a Guid or a GroupName. Cannot use this is there is no permission to create Azure AD Groups. Check the documentation to correct " + $using:ConfigFile + " and try again.")
                }
                else {
                    Write-Verbose ($value + " is a Group. Will attempt to use.")
                    $variablesToPublishinLoop += @{ ("azureADGroupId_" + $name) = $value }
                }
            }
            $variablesToPublishinLoop
        }
        $rjob = $job | Wait-Job | Receive-Job
        foreach ($item in $rjob) {
            Publish-Variables -vars $item
            Write-Host ($item.Keys + "variable published as" + $item.Values);
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
