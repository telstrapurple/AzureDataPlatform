#Requires -Version 7.0.0
# We need PowerShell 7+ for the `ConvertFrom-JSON -AsHashtable` switch

function Convert-ToBoolean
(
    [string]$StringValue = "",
    [bool]$Default = $false
) {
    [bool]$result = $Default

    switch -exact ($StringValue) {
        "1" { $result = $true; }
        "-1" { $result = $true; }
        "true" { $result = $true; }
        "True" { $result = $true; }
        "yes" { $result = $true; }
        "y" { $result = $true; }
        "0" { $result = $false; }
        "false" { $result = $false; }
        "False" { $result = $false; }
        "no" { $result = $false; }
        "n" { $result = $false; }
    }
    return $result
}
function Test-Any() {
    begin {
        $any = $false
    }
    process {
        $any = $true
    }
    end {
        $any
    }
}

function Assert-Guid([string] $displayNameObjectId) {
    try {
        [System.Guid]::Parse($displayNameObjectId)
        return $true
    }
    catch {
        return $false
    }
}

function Join-HashTables([Hashtable] $ht1, [Hashtable] $ht2) {
    $keys = $ht1.getenumerator() | foreach-object { $_.key }
    $keys | foreach-object {
        $key = $_
        if ($ht2.containskey($key)) {
            $ht1.remove($key)
        }
    }
    $ht = $ht1 + $ht2
    return $ht
}

function ConvertFrom-JsonToHash([string] $Object) {
    # TODO: For now this function is just a shim. Later commits will remove calls to this function entirely
    ConvertFrom-JSON -InputObject $Object -AsHashtable
}

function Initialize-ARMContext([Hashtable] $parameters, [string] $configFilePath) {
    $Config = ConvertFrom-Json ([System.IO.File]::ReadAllText($configFilePath)) -AsHashtable
    $Context = Join-HashTables -ht1 $Config -ht2 $parameters

    if ($env:LOCAL_BUILD -eq "True") {
        $ConfigOverrides = ConvertFrom-JSON -InputObject $env:LOCAL_BUILD_CONFIG_OVERRIDES -AsHashtable
        $ConfigOverrides.Keys | ForEach-Object { $Context[$_] = $ConfigOverrides[$_] }
    }

    $azContext = Get-AzContext
    if (-not $azContext) {
        throw "Execute Connect-AzAccount and try again"
    }

    if ($azContext.Subscription.Id -ne $Context.SubscriptionId) {
        Set-AzContext -SubscriptionId $Context.SubscriptionId -Tenant $Context.TenantId
    }

    return $Context
}

# Combines standard ARM parameters with directly specified values ($with) and environment-specific JSON config values ($configKey)
function Get-Params([Parameter(Mandatory = $true)] [object] $context, [Hashtable] $with, [string] $configKey, [Hashtable] $diagnostics, [string] $purpose) {
    $standardParams = @{
        "tagObject" = @{
            "CompanyName" = $context.CompanyName;
            "Location"    = $context.LocationCode;
            "Application" = $context.AppName;
            "Environment" = $context.EnvironmentCode;
        }
    }
    $configValues = @{}

    if ($purpose) {
        $standardParams.tagObject.Purpose = $purpose
    }
    if ($configKey -and $context[$configKey]) {
        $configValues = $context[$configKey]
    }
    if (-not $with) {
        $with = @{}
    }
    if (-not $diagnostics) {
        $diagnostics = @{}
    }
    return $standardParams + $with + $configValues + $diagnostics
}

function Get-ResourceName([Parameter(Mandatory = $true)] [object] $context, [Parameter(Mandatory = $true)] [string] $resourceCode, [string] $suffix) {
    $parts = @(
        $context.CompanyCode
        $context.LocationCode
        $context.EnvironmentCode
        $context.AppCode
        $resourceCode
    )

    if (-not [string]::IsNullOrEmpty($suffix)) {
        $parts += $suffix
    }

    if ($resourceCode -eq "ARG" -or $resourceCode -eq "LGA") {
        # Return the name in Sentence case. Easier on the eyes!
        return [string]::Join($context.Delimiter, $parts)
    }
    elseif ($resourceCode -eq "STA") {
        return ([string]::Join("", $parts)).ToLowerInvariant()
    }
    else {
        return ([string]::Join($context.Delimiter, $parts)).ToUpperInvariant()
    }
}

function Invoke-ARM {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)] [object] $context,
        [Parameter(Mandatory = $true)] [string] $template,
        [Parameter(Mandatory = $true)] [Hashtable] $parameters,
        [Parameter(Mandatory = $true, ParameterSetName = "RG")] [string] $resourceGroupName,
        [Parameter(Mandatory = $true, ParameterSetName = "SUB")] [string] $location
    )
    Process {
        $templatePath = Join-Path $PSScriptRoot "../../arm/$template.json"

        $name = ("$($context.CompanyCode)-$($context.LocationCode)-$($context.EnvironmentCode)-$($context.AppCode)-$template-")
        if ($name.Length -gt 43) {
            $name = $name.Substring(0, 43)
        }
        $name = $name + $(Get-Date -Format FileDateTimeUniversal)

        $DeploymentTags = @{ 'Source' = 'Local' }
        if (-not [String]::IsNullOrEmpty($ENV:BUILD_DEFINITIONNAME)) { $DeploymentTags['AzDoBuildName'] = $ENV:BUILD_DEFINITIONNAME }
        if (-not [String]::IsNullOrEmpty($ENV:BUILD_BUILDNUMBER)) { $DeploymentTags['AzDoBuildNumber'] = $ENV:BUILD_BUILDNUMBER }

        if (-not [string]::IsNullOrEmpty($resourceGroupName)) {

            Write-Host "$(Get-Date -Format FileDateTimeUniversal) Executing ARM deployment '$name' to Resource Group '$resourceGroupName'."
            $armDeployResult = New-AzResourceGroupDeployment `
                -Name $name `
                -ResourceGroupName $resourceGroupName `
                -TemplateFile $templatePath `
                -TemplateParameterObject $parameters `
                -ErrorAction 'Continue' `
                -SkipTemplateParameterPrompt `
                -Tag $DeploymentTags
        }
        else {

            if ($template -eq "resourceGroup") {
                # Because this is now a process, the ARM template file is locked in the foreach-object -asjob loop. This if solves that by copying the file for each loop and deploys that instead.
                $guid = [guid]::NewGuid();
                Copy-Item $templatePath (Join-Path $PSScriptRoot "../../arm/$guid.json")
                $templatePath = Join-Path $PSScriptRoot "../../arm/$guid.json"
            }


            Write-Host "$(Get-Date -Format FileDateTimeUniversal) Executing ARM deployment '$name' to Subscription."
            $armDeployResult = New-AzDeployment `
                -Name $name `
                -Location $location `
                -TemplateFile $templatePath `
                -TemplateParameterObject $parameters `
                -ErrorAction 'Continue' `
                -SkipTemplateParameterPrompt `
                -Tag $DeploymentTags
        }

        if (-not $armDeployResult -or $armDeployResult.ProvisioningState -ne "Succeeded") {
            Write-Host (ConvertTo-Json $armDeployResult)
            throw "An error occurred deploying resources with ARM. See error output above."
        }

        Write-Host -ForegroundColor Green "`r`n✔️  $(Get-Date -Format FileDateTimeUniversal) ARM deployment '$name' completed successfully.`r`n"

        return $armDeployResult.Outputs
    }
}

function New-LocallyEncryptedSecret([securestring] $secret) {
    $isLocal = $env:LOCAL_BUILD -eq "True"
    if (-not $isLocal) {
        throw "Attempt to call Get-LocallyEncryptedSecret in non-local environment"
    }

    $keyPath = Join-Path $HOME ".keys"
    New-Item -Path $keyPath -ItemType Directory -Force | Out-Null

    $keyFile = Join-Path $keyPath "$($env:LOCAL_BUILD_SECRET_KEY).key"
    if (-not (Test-Path $keyFile)) {
        $key = New-Object Byte[] 32
        [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($key)
        $key | Out-File $keyFile
    }
    else {
        $key = Get-Content $keyFile
    }

    return ConvertFrom-SecureString -Key $key $secret
}

function Get-LocallyEncryptedSecret([string] $encryptedSecret) {
    $isLocal = $env:LOCAL_BUILD -eq "True"
    if (-not $isLocal) {
        throw "Attempt to call Get-LocallyEncryptedSecret in non-local environment"
    }
    $keyFile = Join-Path (Join-Path $HOME ".keys") "$($env:LOCAL_BUILD_SECRET_KEY).key"
    $key = Get-Content $keyFile
    return ConvertTo-SecureString -Key $key -String $encryptedSecret | ConvertFrom-SecureString -AsPlainText
}

function Publish-Variables([Hashtable] $vars, [switch] $isSecret = $false) {
    $isAzureDevOps = $env:TF_BUILD -eq "True"
    $isLocal = $env:LOCAL_BUILD -eq "True"
    $localHash = @{}
    $vars.Keys | ForEach-Object {
        $value = $vars[$_]
        if ($value -is [securestring]) {
            if (-not $isSecret) {
                throw "Attempted to publish a secret variable $_ (secure string) without isSecret flag set"
            }
            $value = ConvertFrom-SecureString -SecureString $value -AsPlainText
        }
        if ($value -isnot [string]) {
            $value = ConvertTo-Json $value -Compress
        }
        [System.Environment]::SetEnvironmentVariable($_, $value, [System.EnvironmentVariableTarget]::Process)
        if ($isAzureDevOps) {
            $attrs = @("task.setvariable variable=$_", "isOutput=true")
            if ($isSecret) {
                $attrs += "isSecret=true"
            }
            $attribString = $attrs -join ";"
            $attribString = $attribString + ";"
            $var = "##vso[$attribString]$value"
            Write-Output $var
        }
        if ($isLocal) {
            if (-not $isSecret) {
                $localHash[$_] = $value
            }
            else {
                $localHash[$_] = "secret:" + (New-LocallyEncryptedSecret (ConvertTo-SecureString -AsPlainText $value))
            }
        }
    }
    if ($isLocal) {
        $jsonFile = $env:LOCAL_BUILD_PUBLISHED_VARS_FILE
        $existingJson = Get-Content -Path $jsonFile -Raw -ErrorAction SilentlyContinue
        if (-not $existingJson) {
            $existingJson = "{}"
        }
        $existing = ConvertFrom-JSON -InputObject $existingJson -AsHashTable
        $existing.Keys | ForEach-Object { if (-not ($localHash[$_])) { $localHash[$_] = $existing[$_] } }
        $newJson = ConvertTo-Json $localHash
        Set-Content -Force -Path $jsonFile -Value $newJson
    }
}

function Get-CurrentIP() {
    return Invoke-RestMethod -Uri "https://ipinfo.io/json" -Verbose:$false | Select-Object -ExpandProperty ip
}

function Get-RandomPassword {
    $password = ConvertTo-SecureString ( -join ((33..38) + (60..64) + (48..57) + (65..90) + (97..122) | Get-Random -Count 48 | foreach-object { [char]$_ })) -AsPlainText -Force
    return $password
}

function Invoke-WithTemporaryNoResourceLocks (
    [Parameter(Mandatory = $true)] [string] $resourceGroupName,
    [Parameter(Mandatory = $true)] [scriptblock] $codeToExecute
) {
    $existingLocks = Get-AzResourceLock -ResourceGroupName $resourceGroupName -AtScope
    $existingLocks | ForEach-Object {
        Write-Host "Temporarily removing resource lock '$($_.Name)' on resource group '$resourceGroupName'"
        Remove-AzResourceLock -LockId $_.LockId -Confirm:$false -Force | Out-Null
    }
    do {
        Start-Sleep 5
    } until ($null -eq (Get-AzResourceLock -ResourceGroupName $resourceGroupName -AtScope))
    try {
        & $codeToExecute
    }
    finally {
        $existingLocks | ForEach-Object {
            Write-Host "Adding back resource lock '$($_.Name)' on resource group '$resourceGroupName'"
            New-AzResourceLock -ResourceGroupName $resourceGroupName -LockName $_.Name -LockLevel $_.Properties.level -LockNotes $_.Properties.notes -Confirm:$false -Force | Out-Null
        }
    }
}
function ConvertTo-Hashtable {
    [CmdletBinding()]
    [OutputType('hashtable')]
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    process {
        ## Return null if the input is null. This can happen when calling the function
        ## recursively and a property is null
        if ($null -eq $InputObject) {
            return $null
        }

        ## Check if the input is an array or collection. If so, we also need to convert
        ## those types into hash tables as well. This function will convert all child
        ## objects into hash tables (if applicable)
        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $InputObject) {
                    ConvertTo-Hashtable -InputObject $object
                }
            )

            ## Return the array but don't enumerate it because the object may be pretty complex
            Write-Output -NoEnumerate $collection
        }
        elseif ($InputObject -is [psobject]) {
            ## If the object has properties that need enumeration
            ## Convert it to its own hash table and return it
            $hash = @{}
            foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
            }
            $hash
        }
        else {
            ## If the object isn't an array, collection, or other object, it's already a hash table
            ## So just return it.
            $InputObject
        }
    }
}

Export-ModuleMember -Function * -Verbose:$false
