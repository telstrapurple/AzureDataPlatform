using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Get variables 
$dataFactoryName = $Request.Query.dataFactoryName
if (-not $dataFactoryName) {
    $dataFactoryName = $Request.Body.dataFactoryName
}
$pipelineRunId = $Request.Query.pipelineRunId
if (-not $pipelineRunId) {
    $pipelineRunId = $Request.Body.pipelineRunId
}

Try
{
    $resource = Get-AzResource -Name $dataFactoryName -ResourceType "Microsoft.DataFactory/factories"
    $resourceGroupName = $resource.ResourceGroupName
    Write-Host $resourceGroupName
    Write-Output $resourceGroupName
    $pipelineRun = Get-AzDataFactoryV2PipelineRun -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -PipelineRunId $pipelineRunId -ErrorAction Stop
    $pipelineRunStatus = $pipelineRun.Status
    $body = $pipelineRunStatus
}
Catch
{   
    $body = $_.Exception.Message
}

if ($pipelineRunId -and $dataFactoryName) {
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
