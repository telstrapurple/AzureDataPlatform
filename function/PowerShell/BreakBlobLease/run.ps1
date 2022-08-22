using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$serviceEndpoint = $Request.Query.serviceEndpoint
if (-not $serviceEndpoint) {
    $serviceEndpoint = $Request.Body.serviceEndpoint
}
$filePath = $Request.Query.filePath
if (-not $filePath) {
    $filePath = $Request.Body.filePath
}
$fileName = $Request.Query.fileName
if (-not $fileName) {
    $fileName = $Request.Body.fileName
}

Try {
    # Get storage account 
    $storageAccounts = Get-AzStorageAccount -ErrorAction SilentlyContinue
    $selectedStorageAccount = $storageAccounts | where-object { $_.PrimaryEndpoints.Dfs -eq $serviceEndpoint -or $_.PrimaryEndpoints.Blob -eq $serviceEndpoint }
    if ($selectedStorageAccount) {
        $key = (Get-AzStorageAccountKey -ResourceGroupName $selectedStorageAccount.ResourceGroupName -name $selectedStorageAccount.StorageAccountName)[0].Value
        $storageAccountName = $selectedStorageAccount.StorageAccountName
        $storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $key
        $containerName = $filePath.Substring(0, $filePath.IndexOf("/"))
        $fileName = $filePath.Replace($containerName + '/', '') + $fileName
        $blob = Get-AzStorageBlob -Context $storageContext -Container $containerName -Blob $fileName
        if ($blob) {
            $leaseState = $blob.ICloudBlob.Properties.LeaseState;
            $leaseStatus = $blob.ICloudBlob.Properties.LeaseStatus;
            if ($leaseStatus -eq "Locked" -and $leaseState -eq "Leased") {
                try {
                    $blob.ICloudBlob.BreakLease()
                    $body = "Successfully broken lease on '$fileName' blob."
                }
                catch {
                    $body = $_.Exception.Message 
                }
            }
            else {
                $body = "The '$fileName' blob's lease state is not Leased."
            }
        }
        else {
            $body = "The '$fileName' blob does not exist"
        }
    }
    else {
        $body = "Cannot find storage account '$storageAccountName' because it does not exist. Please make sure the name of storage is correct."
    }
}
catch {
    $body = $_.Exception.Message
}

# Status code 
if ($serviceEndpoint -and $filePath -and $fileName) {
    $status = [HttpStatusCode]::OK
}
else {
    $status = [HttpStatusCode]::BadRequest
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = $status
        Body       = ($body | Select @{n = "Response"; e = { $body } } | ConvertTo-Json)
    })