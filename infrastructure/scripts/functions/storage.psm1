function Get-StorageContext([string] $Name, [string] $ResourceGroupName) {
    $accountKey = (Get-AzStorageAccountKey -AccountName $Name -ResourceGroupName $ResourceGroupName).Value[0]
    $storageContext = New-AzStorageContext -StorageAccountName $Name -StorageAccountKey $accountKey
    return $storageContext
}

function Set-StorageContainer(
    [Parameter(Mandatory)]
    [Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext] $Context,
    [Parameter(Mandatory)]
    [string] $Name
) {

    if (-not (Get-AzStorageContainer -Name $Name -Context $Context -ErrorAction SilentlyContinue)) {
        Write-Host "$(Get-Date -Format FileDateTimeUniversal) Creating '$Name' storage container in $($Context.StorageAccountName)"
        New-AzStorageContainer -Name $Name -Context $Context -Permission Off | Out-Null
    }
}

Export-ModuleMember -Function * -Verbose:$false
