[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [string]
    $EnvironmentName,

    [Parameter(Mandatory = $true)]
    [string]
    $EnvironmentCode,

    [Parameter(Mandatory = $true)]
    [string]
    $Location,

    [Parameter(Mandatory = $true)]
    [string]
    $LocationCode,

    [Parameter(Mandatory = $true)]
    [string]
    $TenantId,

    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]
    $ConfigFileName,

    [Parameter(Mandatory = $true)]
    [string]
    $DatabricksNotebooksLocation,

    [Parameter(Mandatory = $true)]
    [string]
    $InfrastructureScriptsLocation
)

# Get the name of the deployment Key Vault
$configFilePath = Join-Path -Path $InfrastructureScriptsLocation -ChildPath $ConfigFileName
Import-Module (Join-Path -Path $InfrastructureScriptsLocation -ChildPath './functions/adp.psm1') -Force -Verbose:$false

$context = Initialize-ADPContext -parameters $PSBoundParameters -configFilePath $configFilePath -outputTag:$false
$deploymentKeyVaultName = Get-ResourceName -context $Context -resourceCode 'AKV' -suffix '001'

$databricksWorkspaceUrl = Get-AzKeyVaultSecret -VaultName $deploymentKeyVaultName -Name 'DatabricksWorkspaceUrl'
$databricksWorkspaceUrl = $databricksWorkspaceUrl | Select-Object -ExpandProperty SecretValue | ConvertFrom-SecureString -AsPlainText

$databricksToken = Get-AzKeyVaultSecret -VaultName $deploymentKeyVaultName -Name 'DatabricksToken'
$databricksToken = $databricksToken | Select-Object -ExpandProperty SecretValue | ConvertFrom-SecureString -AsPlainText

# Connect to Databricks
Set-DatabricksEnvironment -ApiRootUrl $databricksWorkspaceUrl -AccessToken $databricksToken

$notebooksPathSegment = 'notebooks'
$notebooksSegmentLength = $notebooksPathSegment.Length

foreach ($file in (Get-ChildItem -Path $DatabricksNotebooksLocation -Recurse -File)) {

    if ($file.Name -eq $file.Extension) {
        continue
    }

    $databricksPath = $file.FullName.Substring($file.FullName.IndexOf($notebooksPathSegment) + $notebooksSegmentLength).Replace($file.Extension, "").Replace('\', '/')
    $notebookPath = $databricksPath.Replace($file.Name.Replace($file.Extension, ""), "")

    # Create the workspace directory

    Add-DatabricksWorkspaceDirectory -Path $notebookPath -ErrorAction SilentlyContinue

    $sourceFilePath = $file.FullName

    $language = switch ($file.extension) {
        '.py' { 'PYTHON' }
        '.ipynb' { 'PYTHON' }
        '.scala' { 'SCALA' }
        '.r' { 'R' }
        '.sql' { 'SQL' }
        default { $null }
    }

    $format = switch ($file.extension) {
        '.py' { 'SOURCE' }
        '.ipynb' { 'JUPYTER' }
        '.scala' { 'SOURCE' }
        '.r' { 'SOURCE' }
        '.sql' { 'SOURCE' }
        default { $null }
    }

    if ([string]::IsNullOrEmpty($language)) {
        Write-Warning ('Unrecognised extension ''{0}'' for file ''{1}''' -f $file.Extension, $file.Name)
        continue
    }

    Write-Host ('Uploading source file ''{0}'' to Databrick path ''{1}''' -f $sourceFilePath, $databricksPath)
    Import-DatabricksWorkspaceItem -Format $format -Path $databricksPath -LocalPath $sourceFilePath -Language $language -Overwrite $true
}