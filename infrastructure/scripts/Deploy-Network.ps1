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
Import-Module (Join-Path $PSScriptRoot "./functions/keyvault.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/storage.psm1") -Force -Verbose:$false

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

        ###############################################################################
        ## DDoS Plan
        ###############################################################################

        if ($Context.create.ddosPlan) {
            $ddosParams = Get-Params -context $Context -with @{
                "ddosPlanName" = Get-ResourceName -context $Context -resourceCode "DDS" -suffix "001";
            }
            $ddos = Invoke-ARM -context $Context -template "ddosPlan" -resourceGroupName $Context.resourceGroupNames.network -parameters $ddosParams
            $ddosPlanId = $ddos.ddosPlanId.value
        }
        else {
            $ddosPlanId = ""
        }

        ###############################################################################
        ## Network Watcher
        ###############################################################################

        if ($Context.create.networkWatcher) {
            $nwaParams = Get-Params -context $Context -with @{
                "nwaName" = Get-ResourceName -context $Context -resourceCode "NWA" -suffix "001";
            }
            $nwa = Invoke-ARM -context $Context -template "networking.networkWatcher" -resourceGroupName $Context.resourceGroupNames.network -parameters $nwaParams
        }

        ###############################################################################
        ## Network Security Groups
        ###############################################################################

        if ($Context.create.virtualNetwork) {
            $generalNsgParams = Get-Params -context $Context -diagnostics $diagnostics -with @{
                "nsgName" = "NSG-General";
            }
            $generalNsg = Invoke-ARM -context $Context -template "networking.nsg.General" -resourceGroupName $Context.resourceGroupNames.network -parameters $generalNsgParams
            $nsgResourceId = $generalNsg.nsgResourceId.value
        }

        ###############################################################################
        ## NAT Gateway
        ###############################################################################

        if ($Context.create.natGateway) {
            $natGatewayParams = Get-Params -context $Context -configKey "natGateway" -with @{
                "gatewayName"         = Get-ResourceName -context $Context -resourceCode "NAT" -suffix "001";
                "gatewayPublicIPName" = Get-ResourceName -context $Context -resourceCode "PIP" -suffix "001";
            }
            $natGateway = Invoke-ARM -context $Context -template "networking.natGateway" -resourceGroupName $Context.resourceGroupNames.network -parameters $natGatewayParams
            $natGatewayResourceId = $natGateway.natGatewayResourceId.value
        }
        else {
            $natGatewayResourceId = ""
        }

        ###############################################################################
        ## Route table
        ###############################################################################

        if ($Context.create.udr) {
            $udrParams = Get-Params -context $Context -with @{
                "udrName"                    = Get-ResourceName -context $Context -resourceCode "UDR" -suffix "001";
                "disableBgpRoutePropagation" = $Context.userDefinedRoute.disableBgpRoutePropagation;
                "routeArray"                 = ConvertTo-HashTable $Context.userDefinedRoute.routes;
            }
            $udr = Invoke-ARM -context $Context -template "networking.udr" -resourceGroupName $Context.resourceGroupNames.network -parameters $udrParams
            $udrResourceId = $udr.udrResourceId.value
        }
        else {
            $udrResourceId = ""
        }

        ###############################################################################
        ## Virtual Network
        ###############################################################################

        if ($Context.create.virtualNetwork) {
            $generalVNetParams = Get-Params -context $Context -configKey "generalNetwork" -diagnostics $diagnostics -purpose "General ADP Network" -with @{
                "ddosPlanId"    = $ddosPlanId;
                "vNetName"      = Get-ResourceName -context $Context -resourceCode "VNT" -suffix ($Context.generalNetwork.vNetCIDR -split "/")[0];
                "nsgResourceId" = $nsgResourceId;
            }
            $generalVNet = Invoke-ARM -context $Context -template "networking.General" -resourceGroupName $Context.resourceGroupNames.network -parameters $generalVnetParams

            $generalNetworkObject = @{
                "vNetResourceId"         = $generalVNet.vNetResourceId.value;
                "subnetVMResourceId"     = $generalVNet.subnetVMResourceId.value;
                "subnetWebAppResourceId" = $generalVNet.subnetWebAppResourceId.value;
            }
        }
        else {
            # Write-Warning "Ensure the customer changes their vNet to use the '$nsgResourceId' NSG and executes our script to create the subnets; see README.md."
            $generalNetworkObject = $Context.generalNetworkIds
        }

        Publish-Variables -vars @{ "generalNetworkObject" = $generalNetworkObject; }

        ###############################################################################
        ## Databricks Network
        ###############################################################################
        if ($Context.create.virtualNetwork) {
            $databricksNsgParams = Get-Params -context $Context -diagnostics $diagnostics -with @{
                "nsgName" = "NSG-Databricks";
            }
            if ($Context.databricks.enableNoPublicIp) {
                $databricksNsg = Invoke-ARM -context $Context -template "networking.nsg.npip.Databricks" -resourceGroupName $Context.resourceGroupNames.network -parameters $databricksNsgParams
            }
            else {
                $databricksNsg = Invoke-ARM -context $Context -template "networking.nsg.pip.Databricks" -resourceGroupName $Context.resourceGroupNames.network -parameters $databricksNsgParams
            }
            $databricksNsgResourceId = $databricksNsg.nsgResourceId.value

            $databricksVNetParams = Get-Params -context $Context -configKey "databricksNetwork" -diagnostics $diagnostics -purpose "Databricks" -with @{
                "ddosPlanId"           = $ddosPlanId;
                "vNetName"             = Get-ResourceName -context $Context -resourceCode "VNT" -suffix ($Context.databricksNetwork.vNetCIDR -split "/")[0];
                "nsgResourceId"        = $databricksNsgResourceId;
                "natGatewayResourceId" = $natGatewayResourceId;
                "udrResourceId"        = $udrResourceId;
            }
            $databricksVNet = Invoke-ARM -context $Context -template "networking.Databricks" -resourceGroupName $Context.resourceGroupNames.network -parameters $databricksVnetParams

            $databricksNetworkObject = @{
                "vNetResourceId"             = $databricksVNet.vNetResourceId.value;
                "subnetDBRPublicResourceId"  = $databricksVNet.subnetDBRPublicResourceId.value;
                "subnetDBRPrivateResourceId" = $databricksVNet.subnetDBRPrivateResourceId.value;
            }
        }
        else {
            # Write-Warning "Ensure the customer changes their vNet to use the '$nsgResourceId' NSG and executes our script to create the subnets; see README.md."
            $databricksNetworkObject = $Context.databricksNetworkIds
        }

        Publish-Variables -vars @{ "databricksNetworkObject" = $databricksNetworkObject; }

        ###############################################################################
        ## vNet Peering
        ###############################################################################
        if ($Context.create.virtualNetwork) {

            $vNetPeeringParams = Get-Params -context $Context -with @{
                "vNetDBRName"     = Get-ResourceName -context $Context -resourceCode "VNT" -suffix ($Context.databricksNetwork.vNetCIDR -split "/")[0];
                "vNetGeneralName" = Get-ResourceName -context $Context -resourceCode "VNT" -suffix ($Context.generalNetwork.vNetCIDR -split "/")[0];
            }
            Invoke-ARM -context $Context -template "networking.vNetPeering" -resourceGroupName $Context.resourceGroupNames.network -parameters $vNetPeeringParams
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
