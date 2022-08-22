# Given the same context as deployment, this script attempts to find all of the resource names that
# could potentially be created/modified as part of the deployment process
[CmdletBinding()]
Param (
  [ValidatePattern("[a-zA-Z0-9\-]{3,24}")]
  [Parameter(Mandatory = $true)]
  [string] $EnvironmentName,

  [Parameter(Mandatory = $true)]
  [ValidatePattern("[a-zA-Z0-9]{1,5}")]
  [string] $EnvironmentCode,

  [Parameter(Mandatory = $true)]
  [ValidatePattern("[a-zA-Z0-9]{1,5}")]
  [string] $Location,

  [Parameter(Mandatory = $true)]
  [ValidatePattern("[a-zA-Z0-9\-]{3,24}")]
  [string] $LocationCode,

  [Parameter(Mandatory = $true)]
  [string] $TenantId,

  [Parameter(Mandatory = $true)]
  [string] $SubscriptionId,

  [Parameter(Mandatory = $false)]
  [string] $ConfigFile = "config.$($EnvironmentCode.ToLower()).json"
)

Set-StrictMode -Version "Latest"
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "./functions/adp.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/core.psm1") -Force -Verbose:$false

$Context = Initialize-ADPContext -parameters $PSBoundParameters -configFilePath (Join-Path $PSScriptRoot $ConfigFile)

$ResourceNames = @{}

Get-ChildItem -Path (Join-Path $PSScriptRoot 'Deploy-*.ps1') | ForEach-Object {
  Write-Verbose "Loading AST for $_"
  $FileName = $_.Name

  # Load the AST
  $Tokens = $ParseErrors = $null
  $Ast = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$Tokens, [ref]$ParseErrors)

  # Find calls to Get-ResourceName
  $Predicate = { param($astObject)
    $astObject -is [System.Management.Automation.Language.CommandAst] -and `
      $astObject.CommandElements.Count -gt 0 -and `
      $astObject.CommandElements[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and `
      $astObject.CommandElements[0].StringConstantType -eq 'BareWord' -and `
      $astObject.CommandElements[0].Value -eq 'Get-ResourceName'
  }

  # Call to Get-ResourceName
  # This is a bit naive as it assumes no in-situ evaluations for parameter values, and that all calls for the context parameter are `-Context $Context`
  $Ast.FindAll($Predicate, $true) | ForEach-Object {
    $AstObject = $_
    try {
      $ResourceName = Invoke-Expression -Command ($AstObject.Extent.ToString())
      if ($ResourceNames.Keys -notcontains $ResourceName) {
        $ResourceNames[$ResourceName] = [PSCustomObject]@{
          Name      = $ResourceName
          Locations = @()
        }
      }
      $ResourceNames[$ResourceName].Locations += "$($FileName):$($AstObject.Extent.StartLineNumber)"
    }
    catch {
      Write-Warning "Could not evaulate the Get-ResourceName statement in $($FileName):$($AstObject.Extent.StartLineNumber) '$($AstObject.Extent.ToString())'"
    }
  } | Out-Null
}

$ResourceNames.Values
