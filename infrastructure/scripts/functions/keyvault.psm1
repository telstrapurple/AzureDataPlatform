function Get-OrSetKeyVaultSecret($keyVaultName, $secretName, $secretValue) {
    $secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -ErrorAction SilentlyContinue
    $secretValueText = $secret | Select-Object -ExpandProperty SecretValue | ConvertFrom-SecureString -AsPlainText
    if (-not $secret -or ($secretValueText -ne $secretValue)) {
        $secretValueSecure = ConvertTo-SecureString -String $secretValue -AsPlainText -Force
        Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -SecretValue $secretValueSecure -ErrorAction Stop | Out-Null
        $secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -ErrorAction SilentlyContinue
    }
    $password = $secret.SecretValue
    $password.MakeReadOnly()
    return $password
}

function Get-OrSetKeyVaultGeneratedSecret {
    param(
        [Parameter(Mandatory)]
        [string] $keyVaultName,

        [Parameter(Mandatory)]
        [string]
        $secretName,

        [Parameter(Mandatory)]
        [ValidateScript( { $_.Ast.ParamBlock.Parameters.Count -eq 0 })]
        [Scriptblock]
        $generator
    )
    $secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -ErrorAction SilentlyContinue
    if (-not $secret) {
        $secretValue = & $generator
        if ($secretValue -isnot [SecureString]) {
            $secretValue = $secretValue | ConvertTo-SecureString -AsPlainText -Force
        }
        Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -SecretValue $secretValue -ErrorAction Stop | Out-Null
        $secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -ErrorAction SilentlyContinue
    }
    $password = $secret.SecretValue
    $password.MakeReadOnly()
    return $password
}

function Get-OptionalAzKeyVaultSecretValue {
    param(
        [Parameter(Mandatory)]
        [string] $VaultName,

        [Parameter(Mandatory)]
        [string]
        $Name
    )
    $value = Get-AzKeyVaultSecret -VaultName $VaultName -Name $Name -ErrorAction SilentlyContinue
    if ($value) {
        return $value.SecretValue | ConvertFrom-SecureString -AsPlainText
    }
    return $null
}

function Add-IPToKeyVaultWhitelist {
    param (
        [Parameter(Mandatory = $true)] [string] $resourceGroupName,
        [Parameter(Mandatory = $true)] [string] $keyVaultName,
        [Parameter(Mandatory = $true)] [string] $ip
    )

    Add-AzKeyVaultNetworkRule -ResourceGroupName $resourceGroupName -VaultName $keyVaultName -IpAddressRange "$ip/32" -ErrorAction SilentlyContinue

    $ipRanges = (Get-AzKeyVault -ResourceGroupName $resourceGroupName -VaultName $keyVaultName -ErrorAction SilentlyContinue).NetworkAcls.IpAddressRanges | Out-String
    if ($ipRanges -notmatch "$ip/32") {
        throw "Adding of the IP ($ip) to the Key Vault ($keyVaultName) failed."
    }
}

function Remove-IPFromKeyVaultWhitelist {
    param (
        [Parameter(Mandatory = $true)] [string] $resourceGroupName,
        [Parameter(Mandatory = $true)] [string] $keyVaultName,
        [Parameter(Mandatory = $true)] [string] $ip
    )

    Remove-AzKeyVaultNetworkRule -ResourceGroupName $resourceGroupName -VaultName $keyVaultName -IpAddressRange "$ip/32" -ErrorAction SilentlyContinue

    $ipRanges = (Get-AzKeyVault -ResourceGroupName $resourceGroupName -VaultName $keyVaultName -ErrorAction SilentlyContinue).NetworkAcls.IpAddressRanges | Out-String
    if ($ipRanges -match "$ip/32") {
        throw "Removing IP ($ip) from the Key Vault ($keyVaultName) failed."
    }
}

function Invoke-WithTemporaryKeyVaultFirewallAllowance (
    [Parameter(Mandatory = $true)] [string] $ipToAllow,
    [Parameter(Mandatory = $true)] [string] $keyVaultName,
    [Parameter(Mandatory = $true)] [string] $resourceGroupName,
    [Parameter(Mandatory = $true)] [scriptblock] $codeToExecute
) {

    Write-Host "Temporarily granting $ipToAllow firewall access to the keyvault $keyVaultName"
    Add-IPToKeyVaultWhitelist -resourceGroupName $resourceGroupName -keyVaultName $keyVaultName -ip $ipToAllow

    try {
        & $codeToExecute
    }
    finally {

        Write-Host "Removing $ipToAllow firewall access from the keyvault $keyVaultName"
        Remove-IPFromKeyVaultWhitelist -resourceGroupName $resourceGroupName -keyVaultName $keyVaultName -ip $ipToAllow
    }
}

Export-ModuleMember -Function * -Verbose:$false
