function Get-KeyVaultCertificatePassword {
    $PfxPassword = ConvertTo-SecureString ( -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 48 | foreach-object { [char]$_ })) -AsPlainText -Force
    return $PfxPassword
}

function Request-X509FromAzureKeyVault([string] $KeyVaultName, [string] $CertificateName) {
    $AzKeyVaultCertificateObject = Get-AzKeyVaultCertificate -VaultName $KeyVaultName -Name $CertificateName
    $AzKeyVaultCertificateSecret = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $AzKeyVaultCertificateObject.Name
    $secretValueText = ""
    $ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AzKeyVaultCertificateSecret.SecretValue)
    $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
    $secretByte = [Convert]::FromBase64String($secretValueText)
    $x509Cert = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2($secretByte, "", "Exportable,PersistKeySet")

    return $x509Cert
}

function Out-PfxFile([System.Security.Cryptography.X509Certificates.X509Certificate2] $x509Cert, [SecureString] $pfxPassword, [string] $pfxFilePath) {
    $type = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx
    $pfx = $x509Cert.Export($type, $pfxPassword)
    [System.IO.File]::WriteAllBytes($pfxFilePath, $pfx)
}

function Get-PFXFilePath {
    $PfxFilePath = Join-Path -Path (Get-Location).path -ChildPath "cert.pfx"
    return $PfxFilePath
}

Export-ModuleMember -Function * -Verbose:$false
