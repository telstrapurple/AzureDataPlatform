using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$serverName = $Request.Query.serverName
if (-not $serverName) {
    $serverName = $Request.Body.serverName
}
$databaseName = $Request.Query.databaseName
if (-not $databaseName) {
    $databaseName = $Request.Body.databaseName
}
$sqlQuery = $Request.Query.sqlQuery
if (-not $sqlQuery) {
    $sqlQuery = $Request.Body.sqlQuery
}

Try
    {
        # Get the access token using the function app MSI
        $apiVersion = "2017-09-01"
        $resourceURI = "https://database.windows.net/"
        $tokenAuthURI = $env:MSI_ENDPOINT + "?resource=$resourceURI&api-version=$apiVersion"
        $tokenResponse = Invoke-RestMethod -Method Get -Headers @{"Secret"="$env:MSI_SECRET"} -Uri $tokenAuthURI
        $accessToken = $tokenResponse.access_token

        # Establish a connection
        $sqlConn = New-Object System.Data.SqlClient.SqlConnection("Data Source=$serverName;Initial Catalog=$databaseName")
        $sqlConn.AccessToken = $accessToken
        $sqlConn.Open()
        # Execute the query and return a result
        $sqlCommand = New-Object System.Data.SqlClient.SqlCommand
        $sqlCommand.Connection = $sqlConn
        $sqlCommand.CommandTimeout = 0
        $sqlCommand.CommandText = $sqlQuery

        # Return the result set
        $dataTable = New-Object System.Data.DataTable
        $sqlReader = $sqlCommand.ExecuteReader()
        $dataTable.Load($sqlReader)
        # Close the connection
        $sqlConn.Close()
        # Return the result set as a json array
        if($dataTable.Rows.Count -eq 1){
            $body = '{"Result": [' + ($dataTable | ConvertTo-Csv -NoTypeInformation | ConvertFrom-Csv | ConvertTo-Json -Compress) + ']}'
        }
        elseif($dataTable.Rows.Count -gt 1){
            $body = '{"Result": ' + ($dataTable | ConvertTo-Csv -NoTypeInformation | ConvertFrom-Csv | ConvertTo-Json -Compress) + '}'
        }
        else {
            $body = '{"Result": ""}'
        }
    }
catch
{
    $body = $_.Exception.Message
}

# Status code 
if ($serverName -and $databaseName -and $sqlQuery) 
{
    $status = [HttpStatusCode]::OK
}
else 
{
    $status = [HttpStatusCode]::BadRequest
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})