[CmdletBinding()]
param(
    [parameter(Mandatory = $true)][string]$automationAccountName,
    [parameter(Mandatory = $true)][string]$resourceGroupName,
    [parameter(Mandatory = $true)][string]$subscriptionId,
    [parameter(Mandatory = $true)][string]$tenantID,
    [parameter(Mandatory = $true)][string]$keyVaultName,
    [parameter(Mandatory = $true)][string]$tempDirectory
)

# #### granting SP access to KeyVault
# $permissionsToCertificates = @("get", "list", "delete", "create", "import", "update", "managecontacts", "getissuers", "listissuers", "setissuers", "deleteissuers", "manageissuers", "recover", "purge", "backup", "restore")
# $permissionsToKeys = @("decrypt", "encrypt", "unwrapKey", "wrapKey", "verify", "sign", "get", "list", "update", "create", "import", "delete", "backup", "restore", "recover", "purge")
# $permissionsToSecrets = @("get", "list", "set", "delete", "backup", "restore", "recover", "purge")
# $permissionsToStorage = @("get", "list", "delete", "set", "update", "regeneratekey", "getsas", "listsas", "deletesas", "setsas", "recover", "backup", "restore", "purge")
# Set-AzKeyVaultAccessPolicy -ResourceGroupName $resourceGroupName -VaultName $keyVaultName -ObjectId $objectIDWorker -PermissionsToCertificates $permissionsToCertificates -PermissionsToKeys $permissionsToKeys -PermissionsToSecrets $permissionsToSecrets -PermissionsToStorage $permissionsToStorage

##############################################################################################################

[String] $applicationDisplayName = "$automationAccountName"
[String] $SelfSignedCertPlainPassword = [Guid]::NewGuid().ToString().Substring(0, 8) + "!" 
[int] $NoOfMonthsUntilExpired = 36

##############################################################################################################

$CertifcateAssetName = "AzureRunAsCertificate"
$CertificateName = $automationAccountName + $CertifcateAssetName
$PfxCertPathForRunAsAccount = Join-Path $tempDirectory ($CertificateName + ".pfx")
$PfxCertPlainPasswordForRunAsAccount = $SelfSignedCertPlainPassword
$CerCertPathForRunAsAccount = Join-Path $tempDirectory ($CertificateName + ".cer")

Write-Output "Generating the cert using Keyvault..."

$certSubjectName = "cn=" + $certificateName

$Policy = New-AzKeyVaultCertificatePolicy -SecretContentType "application/x-pkcs12" -SubjectName $certSubjectName -IssuerName "Self" -ValidityInMonths $noOfMonthsUntilExpired -ReuseKeyOnRenewal
$AddAzKeyVaultCertificateStatus = Add-AzKeyVaultCertificate -VaultName $keyVaultName -Name $certificateName -CertificatePolicy $Policy 
  
While ($AddAzKeyVaultCertificateStatus.Status -eq "inProgress") {
    Start-Sleep -s 10
    $AddAzKeyVaultCertificateStatus = Get-AzKeyVaultCertificateOperation -VaultName $keyVaultName -Name $certificateName
}
 
if ($AddAzKeyVaultCertificateStatus.Status -ne "completed") {
    Write-Error -Message "Key vault cert creation is not sucessful and its status is: $status.Status" 
}

$secretRetrieved = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $certificateName
$pfxBytes = [System.Convert]::FromBase64String($secretRetrieved.SecretValueText)
$certCollection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
$certCollection.Import($pfxBytes, $null, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
   
#Export  the .pfx file 
$protectedCertificateBytes = $certCollection.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, $PfxCertPlainPasswordForRunAsAccount)
[System.IO.File]::WriteAllBytes($PfxCertPathForRunAsAccount, $protectedCertificateBytes)

#Export the .cer file 
$cert = Get-AzKeyVaultCertificate -VaultName $keyVaultName -Name $certificateName
$certBytes = $cert.Certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
[System.IO.File]::WriteAllBytes($CerCertPathForRunAsAccount, $certBytes)

##############################################################################################################

Write-Output "Creating service principal..."
# Create Service Principal
$PfxCert = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList @($PfxCertPathForRunAsAccount, $PfxCertPlainPasswordForRunAsAccount)
    
$keyValue = [System.Convert]::ToBase64String($PfxCert.GetRawCertData())
$KeyId = [Guid]::NewGuid() 

$startDate = Get-Date
$endDate = (Get-Date $PfxCert.GetExpirationDateString()).AddDays(-1)

# Use Key credentials and create AAD Application
$Application = New-AzADApplication -DisplayName $applicationDisplayName -HomePage ("http://" + $applicationDisplayName) -IdentifierUris ("http://" + $KeyId)
New-AzADAppCredential -ApplicationId $Application.ApplicationId -CertValue $keyValue -StartDate $startDate -EndDate $endDate 
New-AzADServicePrincipal -ApplicationId $Application.ApplicationId 

# Sleep here for a few seconds to allow the service principal application to become active (should only take a couple of seconds normally)
Start-Sleep -s 15

$NewRole = $null
$Retries = 0;
While (($null -eq $NewRole) -and ($Retries -le 6)) {
    New-AzRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $Application.ApplicationId -scope ("/subscriptions/" + $subscriptionId + "/resourceGroups/" + $resourceGroupName) -ErrorAction SilentlyContinue
    Start-Sleep -s 10
    $NewRole = Get-AzRoleAssignment -ServicePrincipalName $Application.ApplicationId -ErrorAction SilentlyContinue
    $Retries++;
}

##############################################################################################################
    
Write-Output "Creating Certificate in the Asset..."
# Create the automation certificate asset
$CertPassword = ConvertTo-SecureString $PfxCertPlainPasswordForRunAsAccount -AsPlainText -Force   
Remove-AzAutomationCertificate -ResourceGroupName $resourceGroupName -automationAccountName $automationAccountName -Name $certifcateAssetName -ErrorAction SilentlyContinue
New-AzAutomationCertificate -ResourceGroupName $resourceGroupName -automationAccountName $automationAccountName -Path $PfxCertPathForRunAsAccount -Name $certifcateAssetName -Password $CertPassword -Exportable  | write-verbose

##############################################################################################################

# Populate the ConnectionFieldValues
$ConnectionTypeName = "AzureServicePrincipal"
$ConnectionAssetName = "AzureRunAsConnection"
$ApplicationId = $Application.ApplicationId 
$Thumbprint = $PfxCert.Thumbprint
$ConnectionFieldValues = @{"ApplicationId" = $ApplicationID; "TenantId" = $TenantID; "CertificateThumbprint" = $Thumbprint; "SubscriptionId" = $subscriptionId } 
# Create a Automation connection asset named AzureRunAsConnection in the Automation account. This connection uses the service principal.
   
Write-Output "Creating Connection in the Asset..."
Remove-AzAutomationConnection -ResourceGroupName $resourceGroupName -automationAccountName $automationAccountName -Name $connectionAssetName -Force -ErrorAction SilentlyContinue
New-AzAutomationConnection -ResourceGroupName $resourceGroupName -automationAccountName $automationAccountName -Name $connectionAssetName -ConnectionTypeName $connectionTypeName -ConnectionFieldValues $connectionFieldValues 
    
##############################################################################################################

Write-Output "RunAsAccount Creation Completed..."