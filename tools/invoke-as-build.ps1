<#
.SYNOPSIS
    Build and transfer B&R Automation Studio projects with auto-detection and advanced features.

.DESCRIPTION
    This script wraps BR.AS.Build.exe and PVITransfer.exe to provide:
    - Auto-detection of AS/PVI installation from Windows registry
    - Project version matching to installed AS version
    - Configuration discovery from project files
    - Build all configurations support
    - Auto-generation of PIL files for transfer
    - Colored error/warning output with counts

.PARAMETER ProjectPath
    Path to the Automation Studio project directory (containing .apj file)

.PARAMETER Configuration
    Configuration name to build. Use "all" to build all configurations.
    If not specified, reads from LastUser.set

.PARAMETER Action
    The action to perform: Build, Transfer, BuildAndTransfer, Clean, Rebuild
    Default: Build

.PARAMETER ShowWarnings
    Show warnings in output. By default only errors are displayed.

.PARAMETER PILFile
    Path to PIL file for transfer. If not specified, auto-generates one.

.PARAMETER TargetIP
    Target IP address for auto-generated PIL file transfers.
    Default: 127.0.0.1 (localhost/ARsim)

.PARAMETER InstallMode
    Install mode for transfer: Consistent, InstallDuringTaskOperation
    Default: Consistent

.PARAMETER NoClean
    Skip cleaning before build

.PARAMETER BuildPIP
    Generate a Project Installation Package after build

.EXAMPLE
    .\Invoke-ASBuild.ps1 -ProjectPath "C:\Projects\MyMachine"

.EXAMPLE
    .\Invoke-ASBuild.ps1 -ProjectPath "C:\Projects\MyMachine" -Configuration "all" -ShowWarnings

.EXAMPLE
    .\Invoke-ASBuild.ps1 -ProjectPath "C:\Projects\MyMachine" -Action BuildAndTransfer -TargetIP "192.168.1.100"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$ProjectPath,

    [Parameter()]
    [AllowEmptyString()]
    [string]$Configuration = "",

    [Parameter()]
    [ValidateSet("Build", "Transfer", "BuildAndTransfer", "Clean", "Rebuild")]
    [string]$Action = "Build",

    [Parameter()]
    [switch]$ShowWarnings,

    [Parameter()]
    [string]$PILFile,

    [Parameter()]
    [string]$TargetIP = "127.0.0.1",

    [Parameter()]
    [ValidateSet("Consistent", "InstallDuringTaskOperation")]
    [string]$InstallMode = "Consistent",

    [Parameter()]
    [switch]$NoClean,

    [Parameter()]
    [switch]$BuildPIP
)

#region Classes and Types

class ASInstallation {
    [string]$Version
    [string]$Path
    [string]$SharedPath
    
    ASInstallation([string]$version, [string]$path, [string]$sharedPath) {
        $this.Version = $version
        $this.Path = $path
        $this.SharedPath = $sharedPath
    }
}

class BuildResult {
    [string]$Configuration
    [int]$ExitCode
    [int]$Errors
    [int]$Warnings
    
    BuildResult([string]$config, [int]$exitCode, [int]$errors, [int]$warnings) {
        $this.Configuration = $config
        $this.ExitCode = $exitCode
        $this.Errors = $errors
        $this.Warnings = $warnings
    }
}

#endregion

#region Registry Detection Functions

function Get-InstalledASVersions {
    <#
    .SYNOPSIS
        Discovers all installed Automation Studio versions from Windows registry
    #>
    $installations = @()
    $regPath = "HKLM:\SOFTWARE\WOW6432Node"
    
    try {
        $keys = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue | 
                Where-Object { $_.PSChildName -like "BR_AS_*" }
        
        foreach ($key in $keys) {
            try {
                $asPath = (Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue).BuRSharedFilesPath
                $sharedPath = (Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue).BuRAutStudioPath
                
                $csKey = Join-Path $key.PSPath "ControlStudio"
                if (Test-Path $csKey) {
                    $version = (Get-ItemProperty -Path $csKey -ErrorAction SilentlyContinue).ProgrVersion
                    if ($asPath -and $version) {
                        $installations += [ASInstallation]::new($version, $asPath, $sharedPath)
                    }
                }
            }
            catch { continue }
        }
    }
    catch {
        Write-Warning "Could not read AS installations from registry: $_"
    }
    
    # Sort by version descending (newest first)
    # Handle versions like "4.07.7.74 SP" by removing SP suffix and normalizing
    return $installations | Sort-Object {
        $cleanVersion = $_.Version -replace '\s*SP.*$', ''  # Remove SP suffix
        $cleanVersion = $cleanVersion -replace '\.(\d)\.(\d)\.', '.0$1.0$2.'  # Pad single digits
        $cleanVersion = $cleanVersion -replace '\.(\d)$', '.0$1'  # Pad final single digit
        try {
            [version]$cleanVersion
        }
        catch {
            [version]"0.0.0.0"
        }
    } -Descending
}

function Get-PVIPath {
    <#
    .SYNOPSIS
        Discovers PVI installation path from Windows registry
    #>
    $regPath = "HKLM:\SOFTWARE\WOW6432Node"
    
    # Try BR_PVI6 first
    $pviKey = Join-Path $regPath "BR_PVI6"
    if (Test-Path $pviKey) {
        $path = (Get-ItemProperty -Path $pviKey -ErrorAction SilentlyContinue).InstallationPath
        if ($path) { return $path }
    }
    
    # Try BR_Automation key
    $brKey = Join-Path $regPath "BR_Automation"
    if (Test-Path $brKey) {
        $path = (Get-ItemProperty -Path $brKey -ErrorAction SilentlyContinue).BuRAutStudioPath
        if ($path) { return $path }
    }
    
    # Fallback to common paths
    $fallbackPaths = @(
        "C:\Program Files (x86)\BRAutomation\PVI6",
        "C:\Program Files (x86)\BRAutomation\PVI4",
        "C:\BRAutomation\PVI6"
    )
    
    foreach ($path in $fallbackPaths) {
        $transferExe = Join-Path $path "PVI\Tools\PVITransfer\PVITransfer.exe"
        if (Test-Path $transferExe) {
            return $path
        }
    }
    
    return $null
}

#endregion

#region Project Parsing Functions

function Get-ProjectFile {
    <#
    .SYNOPSIS
        Finds the .apj file in a project directory
    #>
    param([string]$ProjectDir)
    
    $apjFile = Get-ChildItem -Path $ProjectDir -Filter "*.apj" -File | Select-Object -First 1
    if (-not $apjFile) {
        throw "No .apj file found in: $ProjectDir"
    }
    return $apjFile.FullName
}

function Get-ProjectVersion {
    <#
    .SYNOPSIS
        Extracts the AS version from a project's .apj file
    #>
    param([string]$ApjFile)
    
    $content = Get-Content $ApjFile -Raw
    if ($content -match 'AutomationStudio Version="([\d\.]+)"') {
        return $matches[1]
    }
    return $null
}

function Get-ProjectWorkingVersion {
    <#
    .SYNOPSIS
        Extracts the working version from a project's .apj file
    #>
    param([string]$ApjFile)
    
    $content = Get-Content $ApjFile -Raw
    if ($content -match 'WorkingVersion="([\d\.]+)"') {
        return $matches[1]
    }
    return $null
}

function Get-ProjectConfigurations {
    <#
    .SYNOPSIS
        Discovers all configurations in a project by parsing Physical.pkg
    #>
    param([string]$ProjectDir)
    
    $physicalPkg = Join-Path $ProjectDir "Physical\Physical.pkg"
    if (-not (Test-Path $physicalPkg)) {
        Write-Warning "Physical.pkg not found at: $physicalPkg"
        return @()
    }
    
    $configurations = [System.Collections.ArrayList]@()
    [xml]$xml = Get-Content $physicalPkg
    
    # Find Object elements with Type='Configuration' using namespace-agnostic approach
    $objects = $xml.GetElementsByTagName("Object") | Where-Object { $_.Type -eq "Configuration" }
    
    foreach ($obj in $objects) {
        $configName = $obj.InnerText.Trim()
        if ($configName) {
            $configDir = Join-Path $ProjectDir "Physical\$configName"
            if (Test-Path $configDir) {
                [void]$configurations.Add(@{
                    Name = $configName
                    Directory = $configDir
                    CpuName = Get-ConfigurationCpuName -ConfigDir $configDir
                })
            }
        }
    }
    
    # Always return as array
    return @($configurations)
}

function New-XmlNamespaceManager {
    param([xml]$Xml, [hashtable]$Namespaces)
    
    $nsManager = New-Object System.Xml.XmlNamespaceManager($Xml.NameTable)
    foreach ($key in $Namespaces.Keys) {
        $nsManager.AddNamespace($key, $Namespaces[$key])
    }
    return $nsManager
}

function Get-ConfigurationCpuName {
    <#
    .SYNOPSIS
        Gets the CPU name from a configuration's Config.pkg
    #>
    param([string]$ConfigDir)
    
    $configPkg = Join-Path $ConfigDir "Config.pkg"
    if (-not (Test-Path $configPkg)) {
        return $null
    }
    
    [xml]$xml = Get-Content $configPkg
    
    # Use namespace-agnostic approach
    $cpuObj = $xml.GetElementsByTagName("Object") | Where-Object { $_.Type -eq "Cpu" } | Select-Object -First 1
    if ($cpuObj) {
        return $cpuObj.InnerText.Trim()
    }
    return $null
}

function Get-ActiveConfiguration {
    <#
    .SYNOPSIS
        Reads the active configuration from LastUser.set
    #>
    param([string]$ProjectDir)
    
    $lastUserSet = Join-Path $ProjectDir "LastUser.set"
    if (-not (Test-Path $lastUserSet)) {
        return $null
    }
    
    $content = Get-Content $lastUserSet -Raw
    if ($content -match 'ActiveConfigurationName="([^"]+)"') {
        return $matches[1]
    }
    return $null
}

function Find-CompatibleASInstallation {
    <#
    .SYNOPSIS
        Finds an AS installation compatible with the project version
    #>
    param(
        [string]$ProjectVersion,
        [ASInstallation[]]$Installations
    )
    
    if (-not $ProjectVersion -or $Installations.Count -eq 0) {
        return $Installations | Select-Object -First 1
    }
    
    # Extract major.minor for comparison
    $projParts = $ProjectVersion.Split('.')
    $projMajorMinor = "$($projParts[0]).$($projParts[1])"
    
    foreach ($install in $Installations) {
        $instParts = $install.Version.Split('.')
        $instMajorMinor = "$($instParts[0]).$($instParts[1])"
        
        if ($projMajorMinor -eq $instMajorMinor) {
            return $install
        }
    }
    
    # Return newest if no exact match
    Write-Warning "No exact AS version match for $ProjectVersion. Using newest installed version."
    return $Installations | Select-Object -First 1
}

#endregion

#region Output Functions

function Write-Banner {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Yellow
    Write-Host "  $Title" -ForegroundColor Yellow
    Write-Host ("=" * 60) -ForegroundColor Yellow
}

function Write-Step {
    param([string]$Message)
    Write-Host "`n>> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Failure {
    param([string]$Message)
    Write-Host "[FAILED] $Message" -ForegroundColor Red
}

function Write-BuildOutput {
    <#
    .SYNOPSIS
        Parses and displays build output with colored errors/warnings
    #>
    param(
        [string[]]$Output,
        [switch]$IncludeWarnings
    )
    
    $errorPattern = '.*error \d+:.*'
    $warningPattern = '.*warning \d+:.*'
    
    foreach ($line in $Output) {
        if ($line -match $errorPattern) {
            Write-Host $line -ForegroundColor Red
        }
        elseif ($IncludeWarnings -and $line -match $warningPattern) {
            Write-Host $line -ForegroundColor Yellow
        }
    }
}

function Get-BuildCounts {
    <#
    .SYNOPSIS
        Extracts error and warning counts from build output
    #>
    param([string[]]$Output)
    
    $errors = 0
    $warnings = 0
    
    # Look for "Build: X error(s), Y warning(s)" line
    foreach ($line in $Output) {
        if ($line -match 'Build:\s*(\d+)\s*error\(s\),\s*(\d+)\s*warning\(s\)') {
            $errors = [int]$matches[1]
            $warnings = [int]$matches[2]
            break
        }
    }
    
    return @{ Errors = $errors; Warnings = $warnings }
}

#endregion

#region PIL Generation Functions

function New-TransferPIL {
    <#
    .SYNOPSIS
        Generates a PIL file for PVITransfer
    #>
    param(
        [string]$RUCPackagePath,
        [string]$TargetIP,
        [string]$InstallMode,
        [string]$OutputPath
    )
    
    $pilContent = @"
Connection "Cpu", "/IF=TcpIp /IP=$TargetIP", "/AM=* /SDT=5 /DASESSION=1"
Transfer "$RUCPackagePath", "InstallMode=$InstallMode InstallRestriction=AllowUpdatesWithoutDataLoss KeepPVValues=1 ExecuteInitExit=1 IgnoreVersion=1 AllowDowngrade=0"
"@
    
    # Use ASCII encoding without BOM - required by PVITransfer
    [System.IO.File]::WriteAllText($OutputPath, $pilContent, [System.Text.Encoding]::ASCII)
    return $OutputPath
}

function New-CreatePIPPIL {
    <#
    .SYNOPSIS
        Generates a PIL file to create a Project Installation Package
    #>
    param(
        [string]$RUCPackagePath,
        [string]$OutputDir,
        [string]$PILPath
    )
    
    $pilContent = @"
CreatePIP "$RUCPackagePath", "InstallMode=Consistent InstallRestriction=AllowUpdatesWithoutDataLoss KeepPVValues=1 ExecuteInitExit=0 IgnoreVersion=1 AllowDowngrade=0", "Default", "SupportLegacyAR=1", "DestinationDirectory='$OutputDir'"
"@
    
    # Use ASCII encoding without BOM - required by PVITransfer
    [System.IO.File]::WriteAllText($PILPath, $pilContent, [System.Text.Encoding]::ASCII)
    return $PILPath
}

#endregion

#region Build Functions

function Invoke-Build {
    <#
    .SYNOPSIS
        Executes the build for a single configuration
    #>
    param(
        [string]$BuildExe,
        [string]$ProjectFile,
        [hashtable]$Config,
        [string]$TempPath,
        [string]$OutputPath,
        [bool]$Clean,
        [bool]$Rebuild,
        [bool]$ShowWarnings = $false
    )
    
    $configName = $Config.Name
    Write-Step "Building configuration: $configName"
    
    # Clean if requested
    if ($Clean) {
        Write-Host "Cleaning build artifacts..."
        $cleanArgs = @(
            "`"$ProjectFile`"",
            "-c", $configName,
            "-t", "`"$TempPath`"",
            "-cleanAll"
        )
        $cleanResult = Start-Process -FilePath $BuildExe -ArgumentList $cleanArgs -Wait -PassThru -NoNewWindow
    }
    
    # Build
    $buildArgs = @(
        "`"$ProjectFile`"",
        "-c", $configName,
        "-t", "`"$TempPath`"",
        "-o", "`"$OutputPath`"",
        "-buildMode", "Build",
        "-buildRUCPackage"
    )
    
    if ($Rebuild) {
        $buildArgs += "-all"
    }
    
    $process = Start-Process -FilePath $BuildExe -ArgumentList $buildArgs -Wait -PassThru -NoNewWindow -RedirectStandardOutput "$env:TEMP\asbuild_stdout.txt" -RedirectStandardError "$env:TEMP\asbuild_stderr.txt"
    
    $stdout = @()
    if (Test-Path "$env:TEMP\asbuild_stdout.txt") {
        $stdout = Get-Content "$env:TEMP\asbuild_stdout.txt"
        $stdout | ForEach-Object { Write-Host $_ }
    }
    
    $counts = Get-BuildCounts -Output $stdout
    Write-BuildOutput -Output $stdout -IncludeWarnings:$ShowWarnings
    
    if ($counts.Errors -gt 0 -or $counts.Warnings -gt 0) {
        Write-Host "`nBuild Summary: $($counts.Errors) error(s), $($counts.Warnings) warning(s)" -ForegroundColor $(if ($counts.Errors -gt 0) { "Red" } else { "Yellow" })
    }
    
    return [BuildResult]::new($configName, $process.ExitCode, $counts.Errors, $counts.Warnings)
}

function Invoke-Transfer {
    <#
    .SYNOPSIS
        Executes transfer to PLC
    #>
    param(
        [string]$TransferExe,
        [string]$PILFile
    )
    
    Write-Step "Transferring to target..."
    Write-Host "PIL File: $PILFile"
    
    $transferArgs = @("-silent", "`"$PILFile`"")
    $process = Start-Process -FilePath $TransferExe -ArgumentList $transferArgs -Wait -PassThru -NoNewWindow -RedirectStandardOutput "$env:TEMP\pvitransfer_stdout.txt" -RedirectStandardError "$env:TEMP\pvitransfer_stderr.txt"
    
    # Show any output for debugging
    if (Test-Path "$env:TEMP\pvitransfer_stdout.txt") {
        $stdout = Get-Content "$env:TEMP\pvitransfer_stdout.txt" -ErrorAction SilentlyContinue
        if ($stdout) { $stdout | ForEach-Object { Write-Host $_ } }
    }
    if (Test-Path "$env:TEMP\pvitransfer_stderr.txt") {
        $stderr = Get-Content "$env:TEMP\pvitransfer_stderr.txt" -ErrorAction SilentlyContinue
        if ($stderr) { $stderr | ForEach-Object { Write-Host $_ -ForegroundColor Red } }
    }
    
    return $process.ExitCode
}

#endregion

#region Main Logic

# Resolve project path
$ProjectPath = Resolve-Path $ProjectPath
$projectFile = Get-ProjectFile -ProjectDir $ProjectPath
$projectName = [System.IO.Path]::GetFileNameWithoutExtension($projectFile)

Write-Banner "B&R Automation Studio Build Tool"
Write-Host "Project: $projectName"
Write-Host "Path: $ProjectPath"
Write-Host "Action: $Action"

# Get project version
$projectVersion = Get-ProjectVersion -ApjFile $projectFile
$workingVersion = Get-ProjectWorkingVersion -ApjFile $projectFile
Write-Host "Project Version: $projectVersion (Working: $workingVersion)"

# Find compatible AS installation
$asInstallations = Get-InstalledASVersions
if ($asInstallations.Count -eq 0) {
    Write-Failure "No Automation Studio installations found in registry."
    Write-Host "Falling back to default path..."
    $asPath = "C:\Program Files (x86)\BRAutomation\AS6"
}
else {
    Write-Host "`nInstalled AS versions:"
    foreach ($install in $asInstallations) {
        Write-Host "  - $($install.Version) at $($install.Path)"
    }
    
    $selectedAS = Find-CompatibleASInstallation -ProjectVersion $projectVersion -Installations $asInstallations
    $asPath = $selectedAS.Path
    Write-Host "Selected AS: $($selectedAS.Version)" -ForegroundColor Green
}

$buildExe = Join-Path $asPath "Bin-en\BR.AS.Build.exe"
if (-not (Test-Path $buildExe)) {
    Write-Failure "BR.AS.Build.exe not found at: $buildExe"
    exit 1
}
Write-Host "Build Exe: $buildExe"

# Get PVI path for transfer operations
if ($Action -in @("Transfer", "BuildAndTransfer")) {
    $pviPath = Get-PVIPath
    if (-not $pviPath) {
        Write-Failure "PVI installation not found."
        exit 1
    }
    $transferExe = Join-Path $pviPath "PVI\Tools\PVITransfer\PVITransfer.exe"
    if (-not (Test-Path $transferExe)) {
        Write-Failure "PVITransfer.exe not found at: $transferExe"
        exit 1
    }
    Write-Host "Transfer Exe: $transferExe"
}

# Discover configurations
$allConfigurations = Get-ProjectConfigurations -ProjectDir $ProjectPath
Write-Host "`nAvailable configurations:"
foreach ($cfg in $allConfigurations) {
    Write-Host "  - $($cfg.Name) (CPU: $($cfg.CpuName))"
}

# Determine which configurations to build
$configsToBuild = @()
if ($Configuration -eq "all") {
    $configsToBuild = $allConfigurations
    Write-Host "`nBuilding ALL configurations" -ForegroundColor Cyan
}
elseif ($Configuration -and $Configuration -ne "") {
    $configsToBuild = $allConfigurations | Where-Object { $_.Name -eq $Configuration }
    if ($configsToBuild.Count -eq 0) {
        Write-Failure "Configuration '$Configuration' not found in project."
        exit 1
    }
}
else {
    # Auto-detect from LastUser.set
    $activeConfig = Get-ActiveConfiguration -ProjectDir $ProjectPath
    if ($activeConfig) {
        $configsToBuild = @($allConfigurations | Where-Object { $_.Name -eq $activeConfig })
        if ($configsToBuild.Count -gt 0) {
            Write-Host "`nUsing active configuration from LastUser.set: $activeConfig" -ForegroundColor Cyan
        }
    }
    
    # Fallback to first configuration if nothing found
    if ($configsToBuild.Count -eq 0 -and $allConfigurations.Count -gt 0) {
        $firstConfig = $allConfigurations | Select-Object -First 1
        $configsToBuild = @($firstConfig)
        Write-Host "`nUsing first configuration: $($firstConfig.Name)" -ForegroundColor Cyan
    }
    elseif ($configsToBuild.Count -eq 0) {
        Write-Failure "No configurations found in project."
        exit 1
    }
}

# Set paths
$tempPath = Join-Path $ProjectPath "Temp"
$outputPath = Join-Path $ProjectPath "Binaries"

Write-Host ("=" * 60) -ForegroundColor Yellow

# Execute action
$buildResults = @()
$exitCode = 0

switch ($Action) {
    "Clean" {
        foreach ($config in $configsToBuild) {
            Write-Step "Cleaning configuration: $($config.Name)"
            $cleanArgs = @(
                "`"$projectFile`"",
                "-c", $config.Name,
                "-t", "`"$tempPath`"",
                "-cleanAll"
            )
            $process = Start-Process -FilePath $buildExe -ArgumentList $cleanArgs -Wait -PassThru -NoNewWindow
            if ($process.ExitCode -ne 0) {
                $exitCode = $process.ExitCode
            }
        }
        if ($exitCode -eq 0) {
            Write-Success "Clean completed successfully"
        }
        else {
            Write-Failure "Clean failed with exit code: $exitCode"
        }
    }
    
    "Build" {
        foreach ($config in $configsToBuild) {
            $result = Invoke-Build -BuildExe $buildExe -ProjectFile $projectFile -Config $config `
                -TempPath $tempPath -OutputPath $outputPath -Clean (-not $NoClean) -Rebuild $false -ShowWarnings $ShowWarnings
            $buildResults += $result
            
            if ($result.ExitCode -ne 0) {
                $exitCode = $result.ExitCode
            }
        }
        
        # Build PIP if requested
        if ($BuildPIP -and $exitCode -eq 0) {
            foreach ($config in $configsToBuild) {
                Write-Step "Creating PIP for: $($config.Name)"
                $rucPackage = Join-Path $outputPath "$($config.Name)\$($config.CpuName)\RUCPackage\RUCPackage.zip"
                if (Test-Path $rucPackage) {
                    $pipDir = Join-Path $ProjectPath "PIP"
                    if (-not (Test-Path $pipDir)) { New-Item -ItemType Directory -Path $pipDir | Out-Null }
                    
                    $pipPil = Join-Path $ProjectPath "CreatePIP.pil"
                    New-CreatePIPPIL -RUCPackagePath $rucPackage -OutputDir $pipDir -PILPath $pipPil
                    
                    $pipResult = Invoke-Transfer -TransferExe $transferExe -PILFile $pipPil
                    if ($pipResult -eq 0) {
                        Write-Success "PIP created at: $pipDir"
                    }
                }
            }
        }
    }
    
    "Rebuild" {
        foreach ($config in $configsToBuild) {
            $result = Invoke-Build -BuildExe $buildExe -ProjectFile $projectFile -Config $config `
                -TempPath $tempPath -OutputPath $outputPath -Clean $true -Rebuild $true -ShowWarnings $ShowWarnings
            $buildResults += $result
            
            if ($result.ExitCode -ne 0) {
                $exitCode = $result.ExitCode
            }
        }
    }
    
    "Transfer" {
        $config = $configsToBuild | Select-Object -First 1
        
        if ($PILFile -and (Test-Path $PILFile)) {
            $pilToUse = $PILFile
        }
        else {
            # Auto-generate PIL
            $rucPackage = Join-Path $outputPath "$($config.Name)\$($config.CpuName)\RUCPackage\RUCPackage.zip"
            if (-not (Test-Path $rucPackage)) {
                Write-Failure "RUC package not found. Build the project first."
                Write-Host "Expected: $rucPackage"
                exit 1
            }
            
            $pilToUse = Join-Path $ProjectPath "AutoTransfer.pil"
            Write-Host "Auto-generating PIL file for target: $TargetIP"
            New-TransferPIL -RUCPackagePath $rucPackage -TargetIP $TargetIP -InstallMode $InstallMode -OutputPath $pilToUse
        }
        
        $exitCode = Invoke-Transfer -TransferExe $transferExe -PILFile $pilToUse
        
        if ($exitCode -eq 0) {
            Write-Success "Transfer completed successfully"
        }
        else {
            Write-Failure "Transfer failed with exit code: $exitCode"
        }
    }
    
    "BuildAndTransfer" {
        # Build first
        $buildHadErrors = $false
        foreach ($config in $configsToBuild) {
            $result = Invoke-Build -BuildExe $buildExe -ProjectFile $projectFile -Config $config `
                -TempPath $tempPath -OutputPath $outputPath -Clean (-not $NoClean) -Rebuild $false -ShowWarnings $ShowWarnings
            $buildResults += $result
            
            if ($result.Errors -gt 0) {
                $buildHadErrors = $true
            }
        }
        
        # Transfer only if build had no errors
        if ($buildHadErrors) {
            Write-Host "`n[INFO] Transfer skipped due to build errors." -ForegroundColor Yellow
            Write-Host "       Fix the errors above and run again." -ForegroundColor Yellow
        }
        else {
            $config = $configsToBuild | Select-Object -First 1
            
            if ($PILFile -and (Test-Path $PILFile)) {
                $pilToUse = $PILFile
            }
            else {
                $rucPackage = Join-Path $outputPath "$($config.Name)\$($config.CpuName)\RUCPackage\RUCPackage.zip"
                $pilToUse = Join-Path $ProjectPath "AutoTransfer.pil"
                Write-Host "Auto-generating PIL file for target: $TargetIP"
                New-TransferPIL -RUCPackagePath $rucPackage -TargetIP $TargetIP -InstallMode $InstallMode -OutputPath $pilToUse
            }
            
            $transferResult = Invoke-Transfer -TransferExe $transferExe -PILFile $pilToUse
            
            if ($transferResult -eq 0) {
                Write-Success "Transfer completed successfully"
            }
            else {
                Write-Failure "Transfer failed with exit code: $transferResult"
                $exitCode = $transferResult
            }
        }
    }
}

# Summary
Write-Banner "Build Summary"

if ($buildResults.Count -gt 0) {
    $totalErrors = ($buildResults | Measure-Object -Property Errors -Sum).Sum
    $totalWarnings = ($buildResults | Measure-Object -Property Warnings -Sum).Sum
    
    foreach ($result in $buildResults) {
        $status = if ($result.ExitCode -eq 0) { "OK" } else { "FAILED" }
        $color = if ($result.ExitCode -eq 0) { "Green" } else { "Red" }
        Write-Host "  $($result.Configuration): $status ($($result.Errors) errors, $($result.Warnings) warnings)" -ForegroundColor $color
    }
    
    Write-Host "`nTotal: $totalErrors error(s), $totalWarnings warning(s)"
}

Write-Host ("=" * 60) -ForegroundColor Yellow

if ($exitCode -eq 0) {
    Write-Host "  Operation completed successfully!" -ForegroundColor Green
}
else {
    Write-Host "  Operation failed!" -ForegroundColor Red
}

Write-Host ("=" * 60) -ForegroundColor Yellow

exit $exitCode

#endregion
