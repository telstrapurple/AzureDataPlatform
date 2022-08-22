[CmdletBinding(SupportsShouldProcess = $true)]
Param(
    [ValidateScript( { Test-Path $_ -PathType Leaf })]
    [string] $configFilePath = $(Join-Path $PSScriptRoot 'config.dev.json'),

    [ValidateScript( { Test-Path $_ -PathType Leaf })]
    [string] $schemaFilePath = $(Join-Path $PSScriptRoot 'config.schema.json')
)

Write-Host "Testing config file $(Resolve-Path $configFilePath)"
Write-Host "against schema file $(Resolve-Path $schemaFilePath)"
Write-Host ""
Test-Json -Json $(Get-Content $configFilePath -Raw) -SchemaFile $schemaFilePath