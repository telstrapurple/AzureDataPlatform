<#
    .SYNOPSIS 
        Deploys all .pbix files found to specified workspaces
    .DESCRIPTION
        .PARAMETER path path root folder
    
    .EXAMPLE
        Deploy-PowerBIReports.ps1 -path ".\powerbi\demo" -tenantId "<tenantId>" -applicationId "<applicationId>" -applicationKey "<Password>" -environment "production"

    .NOTES
        Pre-requisites: MicrosoftPowerBIMgmt module is installed. If not installed, then run `Install-Module -Name MicrosoftPowerBIMgmt`
#>

[CmdletBinding()]
param (
    [parameter(Mandatory = $true)][String]$path,
    [parameter(Mandatory = $true)][String]$tenantId,
    [parameter(Mandatory = $true)][String]$applicationId,
    [parameter(Mandatory = $true)][String]$applicationKey,
    [parameter(Mandatory = $true)][String]$environment
)

Import-Module MicrosoftPowerBIMgmt

$applicationKeySecure = ConvertTo-SecureString -String $applicationKey -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $applicationId, $applicationKeySecure
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $credential -TenantId $tenantId

if (!(Test-Path -Path $path)) { Write-Host 'Specified path does not exist' } else {
    Get-ChildItem -Path $path -Filter *.pbix -Recurse  | ForEach-Object {
        $pathToFile = $_.FullName -replace $_.Name, ""
        $fullName = $_.FullName
        $configPath = $pathToFile + "config.json"
        $config = Get-Content -Raw -Path $configPath -ErrorAction SilentlyContinue | ConvertFrom-Json
        if ($null -eq $config) {
            Write-Warning "Could not get config file for $fullName"
        }
        if ($config.environment.$environment.deploy) {
            $contentName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
            Write-Host $contentName
            $reports = Get-PowerBIReport -WorkspaceId $config.environment.$environment.workspaceId -Name $contentName
            $reports | ForEach-Object {
                # remove existing report so that overwrite can be performed
                Remove-PowerBIReport -WorkspaceId $config.environment.$environment.workspaceId -Id $_.Id
            }
        
            $publishedContent = New-PowerBIReport -Path $fullName -Name $contentName -WorkspaceId $config.environment.$environment.workspaceId -ConflictAction CreateOrOverwrite -ErrorAction SilentlyContinue
            if ($config.environment.$environment.datasetOnly) {
                $report = Get-PowerBIReport -Name $contentName -WorkspaceId $config.environment.$environment.workspaceId
                # Remove-PowerBIReport -Id $publishedContent.Id -WorkspaceId $config.environment.$environment.workspaceId
                Remove-PowerBIReport -Id $report.Id -WorkspaceId $config.environment.$environment.workspaceId
            }
            if ($config.environment.$environment.rebindReportToDataset) {
                $datasetId = $config.environment.$environment.datasetId
                $url = 'groups/' + $config.environment.$environment.workspaceId + '/reports/' + $publishedContent.Id + '/Rebind'
                Invoke-PowerBIRestMethod -Url $url -Method Post -Body ([pscustomobject]@{datasetId = $datasetId } | ConvertTo-Json -Depth 2 -Compress)
            }
            Write-Host "Successfully deployed $fullName"
        }
        # Alter connection string to dataset
        $dataSourcesToUpdate = New-Object System.Collections.Generic.List[System.Object]
        foreach ($item in $config.environment.$environment.connectionProperties) {
            if (($item.oldConnection.database -ne $item.newConnection.database) -or ($item.oldConnection.server -ne $item.newConnection.server)) {
                Write-Host 'Updating data source from' $item.oldConnection 'to' $item.newConnection
                $dataSourcesToUpdate.Add(@{datasourceSelector = @{datasourceType = $item.datasourceType; connectionDetails = $item.oldConnection }; connectionDetails = $item.newConnection })
            }
        }
        if ($dataSourcesToUpdate.Count -gt 0) {
            $headers = Get-PowerBIAccessToken

            # get datasetId
            $url = "https://api.powerbi.com/v1.0/myorg/groups/$($config.environment.$environment.workspaceId)/datasets"
            try { 
                $datasets = Invoke-RestMethod -Headers $headers -Uri $url -Method Get
                Write-Host "Successfully got datasets"
            }
            catch { 
                $exception = $_.Exception
                Write-Verbose "An exception was caught: $($exception.Message)"
                Write-Host $_.ErrorDetails.Message
            }
            foreach ($dataset in $datasets.value) {
                if ($dataset.Name -eq $contentName) {
                    $targetDataset = $dataset
                }
            }
            # connect datasets to respective datastores
            if (!($targetDataset)) { Write-Host 'Could not find dataset with name ' $contentName } else {
                $datasetId = $targetDataset.Id
                Write-Host "datasetId to update": $datasetId

                ## Take Over DataSet
                Invoke-PowerBIRestMethod -Url "groups/$($config.environment.$environment.workspaceId)/datasets/$($datasetId)/Default.TakeOver" -Method Post -Body ""

                # update dataset
                $url = "https://api.powerbi.com/v1.0/myorg/groups/$($config.environment.$environment.workspaceId)/datasets/$($datasetId)/Default.UpdateDatasources"
                $body = ([pscustomobject]@{updateDetails = $dataSourcesToUpdate } | ConvertTo-Json -Depth 10 -Compress)
                try { 
                    Invoke-RestMethod -Headers $headers -Uri $url -Method Post -Body $body -ContentType 'application/json'
                    Write-Host "Successfully updated datasource connection details"
                }
                catch { 
                    $exception = $_.Exception
                    Write-Verbose "An exception was caught: $($exception.Message)"
                    Write-Host $_.ErrorDetails.Message
                }
            }
        }
    }
}
