function New-DatabricksToken {
    [CmdletBinding()]
    param(
        # The AAD token for the Databricks resource
        [Parameter(Mandatory = $true)]
        [string]
        $DatabricksAadToken,

        # The AAD token for the Azure Management API
        [Parameter(Mandatory = $true)]
        [string]
        $ManagementAadToken,

        # The URL of the Databricks workspace
        # i.e. https://<workspace-id>.<digit>.azuredatabricks.net
        [Parameter(Mandatory = $true)]
        [string]
        $DatabricksWorkspaceUrl,

        # The id of the Databricks workspace
        # i.e. /subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.Databricks/workspaces/<workspace-name>
        [Parameter(Mandatory = $true)]
        [string]
        $DatabricksWorkspaceResourceId
    )

    #
    # See:
    #  - https://docs.microsoft.com/en-us/azure/databricks/dev-tools/api/latest/aad/service-prin-aad-token#use-the-management-endpoint-access-token-to-access-the-databricks-rest-api
    #  - https://cloudarchitected.com/2020/01/provisioning-azure-databricks-and-pat-tokens-with-terraform/
    #

    $body = @{
        comment = 'Token generated by New-DatabricksAccessToken on {0}' -f (Get-Date -Format FileDateTimeUniversal)
    }

    $params = @{
        ContentType = 'application/json'
        Headers     = @{
            Accept                                     = 'application/json'
            Authorization                              = 'Bearer {0}' -f $DatabricksAadToken
            'X-Databricks-Azure-SP-Management-Token'   = $ManagementAadToken
            'X-Databricks-Azure-Workspace-Resource-Id' = $DatabricksWorkspaceResourceId
        }
        Body        = $body | ConvertTo-Json -Compress
        Method      = 'POST'
        Uri         = '{0}/api/2.0/token/create' -f $DatabricksWorkspaceUrl
    }

    try {
        $tokenResponse = Invoke-RestMethod @params
        $tokenResponse.token_value
    }
    catch {
        $err = $_
        throw ("Unable to acquire Databricks token. $err")
    }
}

function Get-OrNewAndUpdateDatabricksCluster ($Name, $autoScale, $nodeSize, $clusterType, $minWorkers, $maxWorkers, $terminationDurationMinutes, $pythonVersion, $sparkVersion, $sparkConfig) {
    $exists = Get-DatabricksCluster -Verbose:$false -ErrorAction SilentlyContinue | Where-Object { $_.cluster_name -eq $Name }
    if (-not $exists) {
        Write-Verbose  ((Get-Date -f "hh:mm:ss tt") + " - " + "Creating new Databricks cluster.")

        if ($autoScale) {
            $result = Add-DatabricksCluster `
                -ClusterName $Name `
                -MinWorkers $minWorkers `
                -MaxWorkers $maxWorkers `
                -AutoterminationMinutes $terminationDurationMinutes `
                -PythonVersion $pythonVersion `
                -SparkVersion $sparkVersion `
                -NodeTypeId $nodeSize `
                -DriverNodeTypeId $nodeSize `
                -ClusterMode $clusterType `
                -SparkConf $sparkConfig `
                -ErrorAction Stop `
                -Verbose:$false
        }
        else {
            $result = Add-DatabricksCluster `
                -ClusterName $Name `
                -NumWorkers $maxWorkers `
                -AutoterminationMinutes $terminationDurationMinutes `
                -PythonVersion $pythonVersion `
                -SparkVersion $sparkVersion `
                -NodeTypeId $nodeSize `
                -DriverNodeTypeId $nodeSize `
                -ClusterMode $clusterType `
                -SparkConf $sparkConfig `
                -ErrorAction Stop `
                -Verbose:$false
        }


        Write-Verbose ((Get-Date -f "hh:mm:ss tt") + " - " + "Created new Databricks cluster $Name.")

        do {
            Write-Verbose ((Get-Date -f "hh:mm:ss tt") + " - " + "Waiting 60 seconds (loop) for the Databricks cluster to not be pending.")
            Start-Sleep 60
        } until ((Get-DatabricksCluster -ClusterID $result.cluster_id -Verbose:$false).state -ne "Pending" )

        $cluster = Get-DatabricksCluster -ClusterID $result.cluster_id -Verbose:$false
        if ($cluster.state -ne "Running") {
            Write-Warning "⚠️  Databricks cluster status is not 'Running', but instead is: $($cluster.state) ($($cluster.state_message))"
        }

        if ($cluster.state -eq "Terminated") {
            Write-Host "Cluster state is terminated; sometimes clusters end up in this state when first created. Trying to start the cluster so other config can be applied to it without failing."

            Start-DatabricksCluster -ClusterID $result.cluster_id -Verbose:$false | Out-Null
            do {
                Write-Verbose ((Get-Date -f "hh:mm:ss tt") + " - " + "Waiting 60 seconds (loop) for the Databricks cluster to not be pending to be able to update it.")
                Start-Sleep 60
            } until ((Get-DatabricksCluster -ClusterID $result.cluster_id -Verbose:$false).state -ne "Pending" )

            $cluster = Get-DatabricksCluster -ClusterID $result.cluster_id -Verbose:$false
            if ($cluster.state -ne "Running") {
                Write-Warning "⚠️  Databricks cluster status is not 'Running', but instead is: $($cluster.state) ($($cluster.state_message))"
            }
        }

        return $result
    }
    else {
        Write-Verbose  ((Get-Date -f "hh:mm:ss tt") + " - " + "Updating existing Databricks cluster.")
        Write-Warning "⚠️  Note you cannot change a mode of a cluster from Standard to HighConcurrency and vice-versa. If it's different, this parameter will be ignored. If you are trying to do this, delete the cluster first before running this script."

        if ($exists.state -eq "Terminated") {
            Write-Host "Cluster state is terminated; starting the cluster so config can be applied to it without failing."
            Start-DatabricksCluster -ClusterID $exists.cluster_id -Verbose:$false | Out-Null
            do {
                Write-Verbose ((Get-Date -f "hh:mm:ss tt") + " - " + "Waiting 60 seconds (loop) for the Databricks cluster to not be pending to be able to update it.")
                Start-Sleep 60
            } until ((Get-DatabricksCluster -ClusterID $exists.cluster_id -Verbose:$false).state -ne "Pending" )
        }

        $cluster = Get-DatabricksCluster -ClusterID $exists.cluster_id -Verbose:$false
        if ($cluster.state -ne "Running") {
            Write-Warning "⚠️  Databricks cluster status is not 'Running', but instead is: $($cluster.state) ($($cluster.state_message))"
        }

        if ($autoScale) {
            Update-DatabricksCluster `
                -ClusterID $exists.cluster_id `
                -ClusterName $Name `
                -MinWorkers $minWorkers `
                -MaxWorkers $maxWorkers `
                -AutoterminationMinutes $terminationDurationMinutes `
                -PythonVersion $pythonVersion `
                -SparkVersion $sparkVersion `
                -NodeTypeId $nodeSize `
                -DriverNodeTypeId $nodeSize `
                -SparkConf $sparkConfig `
                -ErrorAction Stop
            | Out-Null
        }
        else {
            Update-DatabricksCluster `
                -ClusterID $exists.cluster_id `
                -ClusterName $Name `
                -NumWorkers $maxWorkers `
                -AutoterminationMinutes $terminationDurationMinutes `
                -PythonVersion $pythonVersion `
                -SparkVersion $sparkVersion `
                -NodeTypeId $nodeSize `
                -DriverNodeTypeId $nodeSize `
                -SparkConf $sparkConfig `
                -ErrorAction Stop
            | Out-Null
        }

        Write-Verbose  ((Get-Date -f "hh:mm:ss tt") + " - " + "Updated new Databricks cluster $Name.")
        return $exists
    }
}

Export-ModuleMember -Function * -Verbose:$false