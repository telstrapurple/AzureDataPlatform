param(
    [string]
    $gatewayKey
)

# init log setting
$logLoc = "$env:SystemDrive\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension\"
if (! (Test-Path($logLoc))) {
    New-Item -path $logLoc -type directory -Force
}
$logPath = "$logLoc\tracelog.log"
"Start to execute gatewayInstall.ps1. `n" | Out-File $logPath

function Now-Value() {
    return (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

function Throw-Error([string] $msg) {
    try {
        throw $msg
    } 
    catch {
        $stack = $_.ScriptStackTrace
        Trace-Log "DMDTTP is failed: $msg`nStack:`n$stack"
    }

    throw $msg
}

function Trace-Log([string] $msg) {
    $now = Now-Value
    try {
        "${now} $msg`n" | Out-File $logPath -Append
    }
    catch {
        #ignore any exception during trace
    }

}

function Run-Process([string] $process, [string] $arguments) {
    Write-Verbose "Run-Process: $process $arguments"
	
    $errorFile = "$env:tmp\tmp$pid.err"
    $outFile = "$env:tmp\tmp$pid.out"
    "" | Out-File $outFile
    "" | Out-File $errorFile	

    $errVariable = ""

    if ([string]::IsNullOrEmpty($arguments)) {
        $proc = Start-Process -FilePath $process -Wait -Passthru -NoNewWindow `
            -RedirectStandardError $errorFile -RedirectStandardOutput $outFile -ErrorVariable errVariable
    }
    else {
        $proc = Start-Process -FilePath $process -ArgumentList $arguments -Wait -Passthru -NoNewWindow `
            -RedirectStandardError $errorFile -RedirectStandardOutput $outFile -ErrorVariable errVariable
    }
	
    $errContent = [string] (Get-Content -Path $errorFile -Delimiter "!!!DoesNotExist!!!")
    $outContent = [string] (Get-Content -Path $outFile -Delimiter "!!!DoesNotExist!!!")

    Remove-Item $errorFile
    Remove-Item $outFile

    if ($proc.ExitCode -ne 0 -or $errVariable -ne "") {		
        Throw-Error "Failed to run process: exitCode=$($proc.ExitCode), errVariable=$errVariable, errContent=$errContent, outContent=$outContent."
    }

    Trace-Log "Run-Process: ExitCode=$($proc.ExitCode), output=$outContent"

    if ([string]::IsNullOrEmpty($outContent)) {
        return $outContent
    }

    return $outContent.Trim()
}

function Download-File([string] $appName, [string] $url, [string] $path) {
    try {
        $ErrorActionPreference = "Stop";
        $client = New-Object System.Net.WebClient
        $client.DownloadFile($url, $path)
        Trace-Log "Download $appName successful. $appName loc: $path"
    }
    catch {
        Trace-Log "Fail to download $appName install file"
        Trace-Log $_.Exception.ToString()
        throw
    }
}

function Install-File([string] $appName, [string] $path, [string] $fileName, [string] $arguments) {
    if ([string]::IsNullOrEmpty($path)) {
        Throw-Error "$appName path is not specified"
    }

    if (!(Test-Path -Path $path)) {
        Throw-Error "Invalid $appName path: $path"
    }
	
    Trace-Log "Start $appName installation"
    Run-Process $fileName $arguments

    if ($appName -eq "Gateway") {
        Start-Sleep -Seconds 30	
    }

    Trace-Log "Installation of $appName is successful"
}

function Update-PathVariable {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Get-ChocolatelyCommandSource {
    $commandSource = (Get-Command -Name "choco.exe" -ErrorAction SilentlyContinue).Source
    return $commandSource
}

function Get-JRE8InstallName {
    $javaInstallName = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName | Where-Object { $_.DisplayName -like 'Java 8*' }).DisplayName
    return $javaInstallName
}
function Get-RegistryProperty([string] $keyPath, [string] $property) {
    Trace-Log "Get-RegistryProperty: Get $property from $keyPath"
    if (! (Test-Path $keyPath)) {
        Trace-Log "Get-RegistryProperty: $keyPath does not exist"
    }

    $keyReg = Get-Item $keyPath
    if (! ($keyReg.Property -contains $property)) {
        Trace-Log "Get-RegistryProperty: $property does not exist"
        return ""
    }

    return $keyReg.GetValue($property)
}

function Get-GatewayInstalledFilePath() {
    $filePath = Get-RegistryProperty "hklm:\Software\Microsoft\DataTransfer\DataManagementGateway\ConfigurationManager" "DiacmdPath"
    if ([string]::IsNullOrEmpty($filePath)) {
        Throw-Error "Get-GatewayInstalledFilePath: Cannot find installed File Path"
    }
    Trace-Log "Gateway installation file: $filePath"

    return $filePath
}

function Register-Gateway([string] $instanceKey) {
    Trace-Log "Register Agent"
    $filePath = Get-GatewayInstalledFilePath
    Run-Process $filePath "-era 8060"
    Run-Process $filePath "-k $instanceKey"
    Trace-Log "Agent registration is successful!"
}

# Download and install Chocolatey and the Java Runtime Environment 8 if they haven't already been

$chocolateyCommandSource = Get-ChocolatelyCommandSource
if ([string]::IsNullOrEmpty($chocolateyCommandSource)) {
    $uri = "https://chocolatey.org/install.ps1"
    $chPath = "$PWD\chocolateyInstall.ps1"
    Trace-Log "Chocolatey download fw link: $uri"
    Trace-Log "Chocolatey download location: $chPath"

    Download-File "Chocolatey" $uri $chPath
    Install-File "Chocolatey" $chPath "powershell.exe" "-ExecutionPolicy Unrestricted -File chocolateyInstall.ps1"
    Update-PathVariable
}

$javaInstallName = Get-JRE8InstallName
if ([string]::IsNullOrEmpty($javaInstallName)) {
    Install-File "JRE8" (Get-ChocolatelyCommandSource) 'choco' 'install jre8 -PackageParameters "/exclude:32" -y'
}

#Download and install gateway if it hasn't already been

if ($null -eq (Get-Process "diahost" -ErrorAction SilentlyContinue)) {
    Trace-Log "Integration Runtime is not running. Initiating Download - Install - Register sequence."

    Trace-Log "Log file: $logLoc"
    $uri = "https://go.microsoft.com/fwlink/?linkid=839822"
    Trace-Log "Gateway download fw link: $uri"
    $gwPath = "$PWD\gateway.msi"
    Trace-Log "Gateway download location: $gwPath"

    Download-File "Gateway" $uri $gwPath
    Install-File "Gateway" $gwPath "msiexec.exe" "/i gateway.msi INSTALLTYPE=AzureTemplate /quiet /norestart"
    Register-Gateway $gatewayKey
}
else {
    Trace-Log "Integration Runtime is already running. Skipping installation but overwrite gateway key."
    & (Get-GatewayInstalledFilePath).replace("diacmd.exe", "dmgcmd.exe") -Key $gatewayKey 
}