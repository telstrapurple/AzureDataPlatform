using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$keyvaultName = $Request.Query.keyvaultName
if (-not $keyvaultName) {
    $keyvaultName = $Request.Body.keyvaultName
}

$secretName = $Request.Query.secretName
if (-not $secretName) {
    $secretName = $Request.Body.secretName
}

try
{
    # Get the secret from KeyVault

    if(!(Get-AzKeyVaultSecret -VaultName $keyvaultName -Name $secretName -ErrorAction SilentlyContinue))
    {
        $body = "The secret named $secretName for KeyVault instance $keyvaultName could not be found"
    }
    else
    {
        $body = (Get-AzKeyVaultSecret -VaultName $keyvaultName -Name $secretName).SecretValueText
    }
}
Catch
{
    $body = $_.Exception.Message
}

# Status code 
if ($keyvaultName -and $secretName) {
    $status = [HttpStatusCode]::OK
}
else {
    $status = [HttpStatusCode]::BadRequest
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = ($body | Select @{n="Response";e={$body}} | ConvertTo-Json)
})
