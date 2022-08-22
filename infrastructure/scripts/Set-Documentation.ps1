function Get-StartIndexForRegex(
    [string] $stringToSearch,
    [regex] $search
) {
    $stringToSearch -imatch $search
    return $stringToSearch.IndexOf($_[0])
}

function Get-EndIndexForTokenClose(
    [string] $stringToSearch,
    [int] $startingIndex,
    [string] $startToken,
    [string] $endToken
) {
    $openCount = 1
    $index = $startingIndex
    do {
        $currentCharacter = $stringToSearch[$index]
        if ($currentCharacter -eq $startToken) {
            $openCount++
        }

        if ($currentCharacter -eq $endToken) {
            $openCount--
        }
        $index++
    } while ($index -eq $stringToSearch.Length -or ($currentCharacter -eq $endToken -and $openCount -eq 0))

    return $index
}

function Get-CodeBlock(
    [string] $code,
    [regex] $blockStartSearch,
    [string] $startToken,
    [string] $endToken
) {

    $match = $blockStartSearch.Match($code)
    if (-not $match.Success) {
        return $null;
    }

    $startIndex = $code.IndexOf($match[0])
    $index = $startIndex
    $openCount = 0

    do {

        $currentCharacter = $code[$index]

        if ($currentCharacter -eq $startToken) {
            $opencount++
        }

        if ($currentCharacter -eq $endToken) {
            $opencount--
        }

        $index++
    } while ($index -lt $code.Length -and -not ($currentCharacter -eq $endToken -and $openCount -eq 0))

    return @{
        "startIndex"     = $startIndex;
        "endIndex"       = $index;
        "blockText"      = $code.Substring($startIndex, $index - $startIndex);
        "innerBlockText" = $code.Substring($startIndex + $match[0].Length, $index - $startIndex - $match[0].Length - 1);
    }
}

function Get-CodeIndexes(
    [string] $code,
    [string] $indexOf,
    [string] $ignoreWithinStartToken,
    [string] $ignoreWithinEndToken
) {

    $index = 0
    $indexes = @()
    $openCount = 0

    do {

        $currentCharacter = $code[$index]

        if ($currentCharacter -eq $ignoreWithinStartToken) {
            $opencount++
        }

        if ($currentCharacter -eq $ignoreWithinEndToken) {
            $opencount--
        }

        if ($currentCharacter -eq $indexOf -and $openCount -eq 0) {
            $indexes += $index
        }

        $index++
    } while ($index -lt $code.Length)

    return $indexes
}

function Get-CodeBlocks(
    [string] $code,
    [string] $splitBy,
    [string] $ignoreWithinStartToken,
    [string] $ignoreWithinEndToken
) {
    $splitIndexes = @(0)
    $blocks = @()

    $splitIndexes = @(0)
    $splitIndexes += (Get-CodeIndexes -code $code -indexOf $splitBy -ignoreWithinStartToken $ignoreWithinStartToken -ignoreWithinEndToken $ignoreWithinEndToken)

    $lastSplitIndex = $splitIndexes[$splitIndexes.Length - 1]
    $lastContent = $code.Substring($lastSplitIndex)
    if (-not [string]::IsNullOrWhiteSpace($lastContent)) {
        $splitIndexes += ($code.Length - 1)
    }

    for ($i = 1; $i -lt $splitIndexes.Length; $i++) {
        $length = $splitIndexes[$i] - $splitIndexes[$i - 1]
        $blocks += $code.Substring($splitIndexes[$i - 1] + $splitBy.Length, $length - $splitBy.Length)
    }

    return $blocks
}

function Get-EndIndexForTokenClose(
    [string] $stringToSearch,
    [int] $startingIndex,
    [string] $startToken,
    [string] $endToken
) {
    $openCount = 0
    $index = $startingIndex
    do {
        $currentCharacter = $stringToSearch[$index]
        if ($currentCharacter -eq $startToken) {
            $openCount++
        }

        if ($currentCharacter -eq $endToken) {
            $openCount--
        }
        $index++
    } while ($index -ne $stringToSearch.Length -and -not ($currentCharacter -eq $endToken -and $openCount -eq 0))

    return $index
}

$ErrorActionPreference = "Stop"

try {

    $standardVars = @("EnvironmentName", "EnvironmentCode", "GlobalAdminGroupId", "Location", "LocationCode", "TenantId", "SubscriptionId", "ConfigFile")

    $modules = @()

    $filesToScan = Get-ChildItem -Path $PSScriptRoot -Filter "Deploy-*.ps1"
    $filesToScan | Foreach-Object {

        $moduleName = $_.Name
        $content = Get-Content -Raw $_.FullName

        # Params
        $params = Get-CodeBlock -code $content -blockStartSearch ([regex]'Param\s*\(') -startToken "(" -endToken ")"
        $varBlocks = Get-CodeBlocks -code $params.innerBlockText -splitBy "," -ignoreWithinStartToken "[" -ignoreWithinEndToken "]"
        $dependencies = @()
        $varBlocks | ForEach-Object {
            $varIndexes = Get-CodeIndexes -code $_ -indexOf "$" -ignoreWithinStartToken "[" -ignoreWithinEndToken "]"
            $varStatement = $_.Substring($varIndexes[0] + 1)
            $split = $varStatement -split "="
            $var = $split[0].Trim()
            if (-not ($standardVars -contains $var)) {
                $dependencies += $var
            }
        }

        # Published Variables
        $publishedVarsBlocks = $content -split "Publish-Variables"
        $publishedVars = @()
        if ($publishedVarsBlocks.Length -gt 1) {
            $publishedVarsBlocks | Select-Object -Skip 1 | ForEach-Object {
                $varsBlock = Get-CodeBlock -code $_ -blockStartSearch ([regex]'-vars\s*@\s*{') -startToken "{" -endToken "}"

                if ($varsBlock -eq $null) {
                    Write-Warning "$($moduleName): No discerable variables from Publish-Variables call"
                    return
                }

                $vars = $varsBlock.innerBlockText -split ";"
                $vars | ForEach-Object {
                    $varNameString = ($_ -split "=")[0]
                    $varName = $varNameString.Trim().Trim('"')
                    if (-not [string]::IsNullOrWhiteSpace($varName)) {
                        $publishedVars += $varName
                    }
                }
            }
        }

        # Patch up things that can't be inferred
        if ($_.Name -eq "Deploy-Identities.ps1") {
            $config = Get-Content -Raw (Join-Path $PSScriptRoot "config.dev.json")
            $configObject = ConvertFrom-Json $config
            $configObject.azureADGroups.PSObject.Properties | ForEach-Object {
                $publishedVars += "azureADGroupId_$($_.Name)"
            }
        }

        # Output
        Write-Host -ForegroundColor Magenta $_.Name
        if ($dependencies.Length) {
            Write-Host " - Dependencies"
            $dependencies | ForEach-Object {
                Write-Host "   - $_"
            }
        }
        if ($publishedVars.Length) {
            Write-Host " - Publishes"
            $publishedVars | ForEach-Object {
                Write-Host "   - $_"
            }
        }

        $modules += @{"Name" = $moduleName; "Dependencies" = $dependencies; "Publishes" = $publishedVars; }
    }

    Import-Module PSGraph
    $a = graph "ADPModules" {
        $modules | ForEach-Object {
            $moduleName = $_.Name
            node $moduleName -Attributes @{"shape" = "house"; "style" = "filled"; "color" = "Red"; "fontcolor" = "white" }
            $_.Publishes | ForEach-Object {
                node $_
                edge -From $moduleName -To $_ -Attributes @{"label" = "publishes" }
            }
            $_.Dependencies | ForEach-Object {
                edge -From $_ -To $moduleName -Attributes @{"label" = "dependsOn" }
            }
        }
    } 

    $a | Export-PSGraph -OutputFormat "pdf" -DestinationPath (Join-Path $PSScriptRoot "../docs/modules.pdf")
    $a | Export-PSGraph -OutputFormat "jpg" -DestinationPath (Join-Path $PSScriptRoot "../docs/images/modules.jpg")

}
catch {
    Write-Host -ForegroundColor Red "Caught an exception of type $($_.Exception.GetType())"
    Write-Host -ForegroundColor Red $_.Exception.Message

    if ($_.ScriptStackTrace) {
        Write-Host -ForegroundColor Red $_.ScriptStackTrace
    }

    if ($_.Exception.InnerException) {
        Write-Host -ForegroundColor Red "Caused by: $($_.Exception.InnerException.Message)"
    }

    throw
}
