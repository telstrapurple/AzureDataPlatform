[CmdletBinding()]
param(

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
    $DataFactoryLocation,

    [Parameter(Mandatory = $true)]
    [string]
    $InfrastructureScriptsLocation
)

$configFilePath = Join-Path -Path $InfrastructureScriptsLocation -ChildPath "./$ConfigFileName"
Import-Module (Join-Path -Path $InfrastructureScriptsLocation -ChildPath './functions/adp.psm1') -Force -Verbose:$false
Import-Module -Name azure.datafactory.tools -Force

$context = Initialize-ADPContext -parameters $PSBoundParameters -configFilePath $configFilePath -outputTag:$false
$dataResourceGroupName = $context.resourceGroupNames.data
$dataFactoryResourceName = Get-ResourceName -context $Context -resourceCode 'ADF' -suffix '001'

$existingDataFactoryResource = Get-AzDataFactoryV2 -ResourceGroupName $dataResourceGroupName -Name $dataFactoryResourceName -ErrorAction SilentlyContinue
if ($null -eq $existingDataFactoryResource) {
    throw 'Unable to find an existing DataFactory resource named ''{0}'' in resource group ''{1}''; Make sure the infrastructure pipeline has been run and the DataFactory resource exists.' -f $dataFactoryResourceName, $dataResourceGroupName
}

$publishDataFactoryOptions = New-AdfPublishOption
$publishDataFactoryOptions.CreateNewInstance = $false

$stageFilePath = Join-Path $PSScriptRoot "stage.csv"
$keyVaultUrl = (Get-AzKeyVault -VaultName (Get-ResourceName -context $Context -resourceCode 'AKV' -suffix '002') -ResourceGroupName $context.resourceGroupNames.security).VaultUri
$functionAppHost = (Get-AzWebApp -Name (Get-ResourceName -context $Context -resourceCode 'FNA' -suffix '001') -ResourceGroupName $context.resourceGroupNames.admin).DefaultHostName

'type,name,path,value
linkedService,KeyVault,typeProperties.baseUrl,' + $keyVaultUrl + '
linkedService,AzureFunction,typeProperties.functionAppUrl,https://' + $functionAppHost `
| Set-Content -Path $stageFilePath -Force

$publishDataFactoryParams = @{
    RootFolder        = $DataFactoryLocation
    ResourceGroupName = $dataResourceGroupName
    DataFactoryName   = $dataFactoryResourceName
    Location          = $location
    Stage             = $stageFilePath
    Option            = $publishDataFactoryOptions
}

Publish-AdfV2FromJson @publishDataFactoryParams