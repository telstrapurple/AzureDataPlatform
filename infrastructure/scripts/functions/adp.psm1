
Import-Module (Join-Path $PSScriptRoot "core.psm1") -Force -Verbose:$false

function Invoke-TelstraPurpleASCII {
    Write-Host @'
                 @@@
                 @@@@@@@@
                 @@@@@@@@@@@
                 @@@@@@@@@@@@@
                 @@@@@@@@@@@@@@@
                 @@@@@@@@@@@@@@@
                 @@@@@@@@@@@@@@@@
                 @@@@@@@@@@@@@@@@
                 @@@@@@@@@@@@@@@
                 @@@@@@@@@@@@@@@
                 @@@@@@@@@@@@@
                 @@@@@@@@@@@
                 @@@@@@@@
                 @@@
@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@                     @@@@@@@@@@@           @@              @@
@@@@@@@@@@@@@@@@@                         @@       @@@@     @@     @@@      @@     @@@@@@     @@@
@@@@@@@@@@@@@@@@@                         @@    @@@    @@@  @@  @@@   @@@  @@@@    @@      @@@   @@
@@@@@@@@@@@@@@@@@                         @@    @@@@@@@@@@  @@   @@@@@@     @@     @@       @@@@@@@
@@@@@@@@@@@@@@@@@                         @@     @@         @@         @@   @@     @@     @@     @@
@@@@@@@@@@@@@@@@@                         @@      @@@@@@    @@   @@@@@@@@   @@@@   @@      @@@@@@@@


                                       @@@@@@@@@@                                   @@
                                       @@      @@@  @@     @@  @@@@@@@  @@@@@@@@    @@      @@@@
                                       @@@@@@@@@    @@     @@  @@       @@    @@@   @@   @@@    @@@
                                       @@           @@     @@  @@       @@@@@@@@    @@   @@@@@@@@@@
                                       @@           @@     @@  @@       @@          @@    @@
                                       @@             @@@@@    @@       @@          @@     @@@@@@
                                                                        @@
'@ -ForegroundColor White
}

function Initialize-ADPContext([Hashtable] $parameters, [string] $configFilePath, [switch] $outputTag) {

    if ($outputTag) {
        Invoke-TelstraPurpleASCII
        Write-Host "----------------------------------------------"
        Write-Host "----- Telstra Purple Azure Data Platform -----"
        Write-Host "----------------------------------------------"
    }

    $Context = Initialize-ARMContext -parameters $parameters -configFilePath $configFilePath

    if ((-not $Context.resourceGroupNames.admin) -or ($Context.resourceGroupNames.admin -eq "auto")) {
        $Context.resourceGroupNames.admin = Get-ResourceName -context $Context -resourceCode "ARG" -suffix "Administration"
    }
    if ((-not $Context.resourceGroupNames.data) -or ($Context.resourceGroupNames.data -eq "auto")) {
        $Context.resourceGroupNames.data = Get-ResourceName -context $Context -resourceCode "ARG" -suffix "Data"
    }
    if ((-not $Context.resourceGroupNames.databricks) -or ($Context.resourceGroupNames.databricks -eq "auto")) {
        $Context.resourceGroupNames.databricks = Get-ResourceName -context $Context -resourceCode "ARG" -suffix "Data-Managed"
    }
    if ((-not $Context.resourceGroupNames.network) -or ($Context.resourceGroupNames.network -eq "auto")) {
        $Context.resourceGroupNames.network = Get-ResourceName -context $Context -resourceCode "ARG" -suffix "Network"
    }
    if ((-not $Context.resourceGroupNames.compute) -or ($Context.resourceGroupNames.compute -eq "auto")) {
        $Context.resourceGroupNames.compute = Get-ResourceName -context $Context -resourceCode "ARG" -suffix "Compute"
    }
    if ((-not $Context.resourceGroupNames.security) -or ($Context.resourceGroupNames.security -eq "auto")) {
        $Context.resourceGroupNames.security = Get-ResourceName -context $Context -resourceCode "ARG" -suffix "Security"
    }
    if ((-not $Context.resourceGroupNames.synapse) -or ($Context.resourceGroupNames.synapse -eq "auto")) {
        $Context.resourceGroupNames.synapse = Get-ResourceName -context $Context -resourceCode "ARG" -suffix "Synapse-Managed"
    }

    return $Context
}

Export-ModuleMember -Function * -Verbose:$false
