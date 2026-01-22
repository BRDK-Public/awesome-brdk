<#
.SYNOPSIS
    Build and transfer B&R Automation Studio projects with auto-detection and advanced features.

.DESCRIPTION
    This script wraps BR.AS.Build.exe and PVITransfer.exe to provide:
    - Auto-detection of AS project in workspace (root or one level down)
    - Auto-detection of AS/PVI installation from Windows registry
    - Project version matching to installed AS version
    - Configuration discovery from project files
    - Build all configurations support
    - Auto-generation of PIL files for transfer
    - Clean terminal output (only errors by default)
    - Dynamic status line showing E:errors W:warnings I:info count

    OUTPUT BEHAVIOR:
    By default, only ERRORS are displayed. This keeps the terminal clean and focused
    on what matters for compilation success. Warnings and build info are hidden unless
    explicitly requested.

    - Errors: Always shown (red) - these prevent successful compilation
    - Warnings: Hidden by default - use -SilenceOutput no to show warnings
    - Build Info: Hidden by default - use -SilenceOutput no to show build details

    WARNING DETECTION:
    Unused variable warnings (warning 5874) and other code quality warnings are only
    generated during full builds/rebuilds when code is actually compiled. Incremental
    builds that skip unchanged files will NOT report these warnings. Use "Rebuild" or
    clean and build to see all warnings.

.PARAMETER ProjectPath
    Path to the Automation Studio project directory (containing .apj file) or
    a workspace directory. If a workspace directory is provided, the script will
    search for .apj files in the root and subdirectories (breadth-first).
    When multiple projects exist at the same depth, prefers the one with a
    LastUser.set file (most recently opened in AS).

.PARAMETER Configuration
    Configuration name to build. Use "all" to build all configurations.
    If not specified, reads from LastUser.set

.PARAMETER Action
    The action to perform: Build, Transfer, BuildAndTransfer, Clean, Rebuild
    - Build: Incremental build (fast, recompiles changed files only)
    - Rebuild: Clean and full rebuild (shows all warnings for recompiled code)
    - Transfer: Transfer RUC package to PLC
    - BuildAndTransfer: Build then transfer
    - Clean: Clean build artifacts
    Default: Build

.PARAMETER SilenceOutput
    When enabled (default "yes"), only errors are shown. Warnings and build info are hidden.
    Set to "no" (-SilenceOutput no) to see full build output including warnings.
    Only disable when specifically debugging build issues or optimizing warnings.
    Warnings do NOT prevent compilation - only errors matter for build success.
    Accepts: "yes", "no", "true", "false" (default: "yes" - silent mode)

.PARAMETER PILFile
    Path to PIL file for transfer. If not specified, auto-generates one.

.PARAMETER TargetIP
    Target IP address for auto-generated PIL file transfers.
    Default: 127.0.0.1 (localhost/ARsim)

.PARAMETER InstallMode
    Install mode for transfer: Consistent, InstallDuringTaskOperation
    Default: Consistent

.PARAMETER NoClean
    Skip cleaning before Rebuild action. By default, Rebuild cleans all build
    artifacts before building. Use this switch to perform a rebuild without
    cleaning first (useful for debugging build issues).

.PARAMETER BuildPIP
    Generate a Project Installation Package after build

.PARAMETER DebugLog
    When specified, logs all build output to a timestamped file in %TEMP% folder.
    Useful for debugging message classification (errors vs warnings vs info).
    File format: as_build_debug_YYYYMMDD_HHMMSS.log

.EXAMPLE
    .\invoke-as-build.ps1 -ProjectPath "C:\Projects\MyWorkspace"
    # Auto-detects project in workspace (prefers recently opened if multiple found)

.EXAMPLE
    .\invoke-as-build.ps1 -ProjectPath "C:\Projects\MyWorkspace\MyProject"
    # Direct project path - shows only errors

.EXAMPLE
    .\invoke-as-build.ps1 -ProjectPath "C:\Projects\MyWorkspace" -SilenceOutput no
    # Shows full output including warnings and build info

.EXAMPLE
    .\invoke-as-build.ps1 -ProjectPath "C:\Projects\MyWorkspace" -Action BuildAndTransfer -TargetIP "192.168.1.100"
    # Build and transfer to PLC

.EXAMPLE
    .\invoke-as-build.ps1 -ProjectPath "C:\Projects\MyWorkspace" -DebugLog
    # Logs all build output to a timestamped file in %TEMP% for debugging message classification
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
    [ValidateSet("yes", "no", "true", "false")]
    [string]$SilenceOutput = "yes",

    [Parameter()]
    [string]$PILFile,

    [Parameter()]
    [string]$TargetIP = "127.0.0.1",

    [Parameter()]
    [ValidateSet("Consistent", "InstallDuringTaskOperation")]
    [string]$InstallMode = "Consistent",

    [Parameter()]
    [switch]$DebugLog,

    [Parameter()]
    [switch]$NoClean,

    [Parameter()]
    [switch]$BuildPIP
)

# Treat 'auto' as empty string for auto-detection
if ($Configuration -eq "auto") {
    $Configuration = ""
}

# Convert SilenceOutput string to boolean
$SilenceOutputBool = $SilenceOutput -in @("yes", "true")

#region Project Discovery

function Find-ASProject {
    <#
    .SYNOPSIS
        Finds an Automation Studio project (.apj file) in the given path or subdirectories.
    .DESCRIPTION
        Uses breadth-first search to find .apj files, checking directories level by level.
        This optimizes for finding projects at shallow depths first, as .apj files are
        typically not deeply nested. Returns the project directory path (not the .apj file path).
    .PARAMETER SearchPath
        The path to search for AS projects.
    .PARAMETER MaxDepth
        Maximum directory depth to search. Default is 10. Use -1 for unlimited.
    .OUTPUTS
        The project directory path, or $null if no project found.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$SearchPath,
        
        [int]$MaxDepth = 10
    )
    
    # Normalize the path
    $SearchPath = $SearchPath.TrimEnd('\', '/')
    
    # BFS queue: each entry is @{ Path = directory path; Depth = current depth }
    $queue = [System.Collections.Queue]::new()
    $queue.Enqueue(@{ Path = $SearchPath; Depth = 0 })
    
    $foundProjects = @()
    $foundAtDepth = -1
    
    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        $currentPath = $current.Path
        $currentDepth = $current.Depth
        
        # If we already found projects at a shallower depth, stop searching deeper
        if ($foundAtDepth -ge 0 -and $currentDepth -gt $foundAtDepth) {
            break
        }
        
        # Check for .apj files in current directory
        $apjFiles = Get-ChildItem -Path $currentPath -Filter "*.apj" -File -ErrorAction SilentlyContinue
        if ($apjFiles) {
            $foundProjects += @{
                Path = $currentPath
                ApjFile = $apjFiles[0].Name
                HasLastUserSet = Test-Path (Join-Path $currentPath "LastUser.set")
                Depth = $currentDepth
            }
            $foundAtDepth = $currentDepth
            # Continue processing same depth level to find all projects at this depth
            continue
        }
        
        # Don't go deeper if we've reached max depth
        if ($MaxDepth -ge 0 -and $currentDepth -ge $MaxDepth) {
            continue
        }
        
        # Enqueue subdirectories for next level
        $subDirs = Get-ChildItem -Path $currentPath -Directory -ErrorAction SilentlyContinue
        foreach ($dir in $subDirs) {
            # Skip common non-project directories for performance
            if ($dir.Name -in @('node_modules', '.git', '.vs', 'Temp', 'Binaries', 'Diagnosis')) {
                continue
            }
            $queue.Enqueue(@{ Path = $dir.FullName; Depth = $currentDepth + 1 })
        }
    }
    
    if ($foundProjects.Count -eq 0) {
        return $null
    }
    
    if ($foundProjects.Count -eq 1) {
        return $foundProjects[0].Path
    }
    
    # Multiple projects found - prefer one with LastUser.set (recently opened)
    $recentProject = $foundProjects | Where-Object { $_.HasLastUserSet } | Select-Object -First 1
    if ($recentProject) {
        return $recentProject.Path
    }
    
    # Fallback to first found
    return $foundProjects[0].Path
}

# Resolve the actual project path
$resolvedProjectPath = Find-ASProject -SearchPath $ProjectPath

if (-not $resolvedProjectPath) {
    Write-Host "ERROR: No Automation Studio project (.apj file) found in:" -ForegroundColor Red
    Write-Host "  - $ProjectPath (or any subdirectory)" -ForegroundColor Red
    exit 1
}

# Update ProjectPath to the resolved path
$ProjectPath = $resolvedProjectPath

#endregion

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

# BR.AS.Build.exe return values (from B&R documentation):
# 0 = No errors or warnings
# 1 = Warnings only (build succeeded)
# 3 = Build error (build failed)
enum ASBuildExitCode {
    Success = 0
    WarningsOnly = 1
    BuildError = 3
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
        Discovers PVI installation path
    .PARAMETER ASPath
        If specified, looks for PVI bundled with this AS installation first.
        This ensures RUC package compatibility.
    #>
    param(
        [string]$ASPath = $null
    )
    
    # First, try to use PVI bundled with the same AS version (for RUC compatibility)
    if ($ASPath) {
        # AS 4.x has PVI in a sibling folder: C:\Program Files\BRAutomation4\PVI\V4.12
        $asParent = Split-Path $ASPath -Parent
        $siblingPviPath = Join-Path $asParent "PVI"
        if (Test-Path $siblingPviPath) {
            # Find the version folder (e.g., V4.12)
            $versionFolder = Get-ChildItem -Path $siblingPviPath -Directory | Where-Object { $_.Name -match '^V\d' } | Select-Object -First 1
            if ($versionFolder) {
                $pviToolsPath = Join-Path $versionFolder.FullName "PVI\Tools\PVITransfer\PVITransfer.exe"
                if (Test-Path $pviToolsPath) {
                    Write-Host "Using bundled PVI: $($versionFolder.FullName)" -ForegroundColor Green
                    return $versionFolder.FullName
                }
            }
        }
    }
    
    $regPath = "HKLM:\SOFTWARE\WOW6432Node"
    
    # Try BR_PVI6 first (standalone PVI installation)
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

function Write-BuildStatus {
    <#
    .SYNOPSIS
        Writes a dynamic status line that updates in place
    .DESCRIPTION
        Uses carriage return to overwrite the same line repeatedly.
        Call with -ClearLine to remove the status line before final output.
    #>
    param(
        [int]$Errors = 0,
        [int]$Warnings = 0,
        [int]$Info = 0,
        [switch]$ClearLine,
        [switch]$NewLineAfter
    )
    
    if ($ClearLine) {
        # Clear the line completely - use large padding to handle any status line length
        Write-Host "`r$(' ' * 120)`r" -NoNewline
        return
    }
    
    $errorColor = if ($Errors -gt 0) { "Red" } else { "DarkGray" }
    $warningColor = if ($Warnings -gt 0) { "Yellow" } else { "DarkGray" }
    
    # Build the status string to calculate its length for proper padding
    $statusText = "Building... E:$Errors W:$Warnings I:$Info"
    $paddingNeeded = [Math]::Max(0, 80 - $statusText.Length)
    
    # Write status with carriage return to stay on same line
    Write-Host "`r" -NoNewline
    Write-Host "Building... " -NoNewline -ForegroundColor Cyan
    Write-Host "E:$Errors " -NoNewline -ForegroundColor $errorColor
    Write-Host "W:$Warnings " -NoNewline -ForegroundColor $warningColor
    Write-Host "I:$Info" -NoNewline -ForegroundColor DarkGray
    Write-Host "$(' ' * $paddingNeeded)" -NoNewline  # Dynamic padding to clear old content
    
    if ($NewLineAfter) {
        Write-Host ""  # Add newline
    }
}

function Write-BuildOutput {
    <#
    .SYNOPSIS
        Parses and displays build output with colored errors/warnings
    .PARAMETER Output
        The build output lines to process
    .PARAMETER IncludeWarnings
        If set, warning lines are displayed in yellow
    .PARAMETER IncludeInfo
        If set, all non-error/warning lines are displayed (verbose mode)
    #>
    param(
        [string[]]$Output,
        [switch]$IncludeWarnings,
        [switch]$IncludeInfo
    )
    
    foreach ($line in $Output) {
        $lineType = Get-LineType -Line $line
        
        if ($lineType -eq 'error') {
            Write-Host $line -ForegroundColor Red
        }
        elseif ($IncludeWarnings -and $lineType -eq 'warning') {
            Write-Host $line -ForegroundColor Yellow
        }
        elseif ($IncludeInfo) {
            # Show all other info lines when not in quiet mode
            Write-Host $line
        }
    }
}

function Get-LineType {
    <#
    .SYNOPSIS
        Determines the type of a build output line
    .PARAMETER Line
        The line to analyze
    .RETURNS
        String indicating line type: 'error', 'warning', or 'info'
    .NOTES
        B&R build output has multiple warning/error formats:
        
        1. Standard AS warnings/errors (IEC-61131 variables, etc.):
           path: (Ln: N) warning NNNN:message
           path: (Ln: N) error NNNN:message
           Example: Variables.var: (Ln: 4) warning 5874:Variable vari is declared local but not used
           
        2. GCC/C++ compiler warnings/errors (includes column):
           path: (Ln: N, Col: N) warning :message [-Wflag]
           path: (Ln: N, Col: N) error :message
           Example: file.cpp: (Ln: 805, Col: 9) warning :enumeration value 'X' not handled [-Wswitch]
           
        3. Package/project level warnings:
           path: (item) warning NNNN:message
           Example: Package.pkg: (file.ext) warning 9232:Additional file found
           
        4. Configuration warnings:
           path:  warning NNNN:message  (note: double space before warning)
           Example: Config.mappviewcfg:  warning 7512:Deprecated license mode
           
        5. Line number in parentheses format:
           path(N): warning NNNN: message
           Example: file.st(123): warning 1234: Some message
    #>
    param(
        [string]$Line
    )
    
    if ([string]::IsNullOrWhiteSpace($Line)) {
        return 'info'
    }
    
    # Error patterns - check these first
    # Pattern 1: Standard AS error with number - "error NNNN:"
    # Pattern 2: GCC error without number - ") error :" (after line/col info)
    if ($Line -match '\)\s+error\s*\d*:' -or $Line -match '\berror\s+\d+:') {
        return 'error'
    }
    
    # Warning patterns - multiple formats from BR.AS.Build.exe
    # Pattern 1: Standard AS warning with number - "warning NNNN:"
    # Pattern 2: GCC warning without number - ") warning :" (after line/col info)
    # Pattern 3: GCC warning with flag - "warning :message [-Wflag]"
    if ($Line -match '\)\s+warning\s*\d*:' -or $Line -match '\bwarning\s+\d+:' -or $Line -match '\[-W\w+\]') {
        return 'warning'
    }
    
    return 'info'
}

# Debug logging - enabled via -DebugLog switch parameter
# Log file location: $env:TEMP\as_build_debug_<timestamp>.log
$script:DebugLogEnabled = $DebugLog
$script:DebugLogPath = Join-Path $env:TEMP "as_build_debug_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-DebugLog {
    <#
    .SYNOPSIS
        Writes a line to the debug log file with classification info
    #>
    param(
        [string]$Line,
        [string]$Classification
    )
    
    if ($script:DebugLogEnabled) {
        $logEntry = "[$Classification] $Line"
        Add-Content -Path $script:DebugLogPath -Value $logEntry -Encoding UTF8
    }
}

function Initialize-DebugLog {
    <#
    .SYNOPSIS
        Initializes the debug log file
    #>
    if ($script:DebugLogEnabled) {
        $header = @"
=============================================================================
B&R Automation Studio Build Output Debug Log
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Purpose: Analyze build output patterns for message classification
=============================================================================

Format: [CLASSIFICATION] Original Line
Classifications: ERROR, WARNING, INFO

=============================================================================
RAW BUILD OUTPUT:
=============================================================================
"@
        Set-Content -Path $script:DebugLogPath -Value $header -Encoding UTF8
        Write-Host "Debug log enabled: $script:DebugLogPath" -ForegroundColor Magenta
    }
}

function Write-ColoredLine {
    <#
    .SYNOPSIS
        Writes a line with color based on its type
    #>
    param(
        [string]$Line,
        [string]$Type
    )
    
    switch ($Type) {
        'error'   { Write-Host $Line -ForegroundColor Red }
        'warning' { Write-Host $Line -ForegroundColor Yellow }
        default   { Write-Host $Line }
    }
}

#endregion

#region PIL Generation Functions

function New-TransferPIL {
    <#
    .SYNOPSIS
        Generates a PIL file for PVITransfer
    .NOTES
        Connection command syntax (from B&R documentation):
        Connection "Device parameters", "CPU parameters", "WT=Waiting time"
        - Device: /IF=tcpip /SA=x (source address)
        - CPU: /DAIP=x.x.x.x (destination IP address)
    #>
    param(
        [string]$RUCPackagePath,
        [string]$TargetIP,
        [string]$InstallMode,
        [string]$OutputPath
    )
    
    $pilContent = @"
Connection "/IF=tcpip /SA=1", "/DAIP=$TargetIP", "WT=30"
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
        [bool]$SilenceOutput = $true
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
    $buildMode = if ($Rebuild) { "Rebuild" } else { "Build" }
    $buildArgs = @(
        "`"$ProjectFile`"",
        "-c", $configName,
        "-t", "`"$TempPath`"",
        "-o", "`"$OutputPath`"",
        "-buildMode", $buildMode,
        "-buildRUCPackage"
    )
    
    $stdout = @()
    $errors = 0
    $warnings = 0
    $infoCount = 0
    $lineCount = 0
    $lastStatusUpdate = [DateTime]::MinValue
    $statusUpdateIntervalMs = 100  # Throttle status updates to every 100ms
    
    # Initialize debug log if this is the first build
    Initialize-DebugLog
    
    # Process build output line-by-line
    & $BuildExe $buildArgs 2>&1 | ForEach-Object {
        $line = $_.ToString()
        $stdout += $line
        $lineCount++
        
        # Determine line type
        $lineType = Get-LineType -Line $line
        
        # Log to debug file
        Write-DebugLog -Line $line -Classification $lineType.ToUpper()
        
        # Update counters
        switch ($lineType) {
            'error'   { $errors++ }
            'warning' { $warnings++ }
            default   { $infoCount++ }
        }
        
        # Throttle status updates for performance (update every 100ms or on errors/warnings)
        $now = [DateTime]::Now
        $timeSinceLastUpdate = ($now - $lastStatusUpdate).TotalMilliseconds
        $shouldUpdateStatus = ($timeSinceLastUpdate -ge $statusUpdateIntervalMs)
        
        if ($SilenceOutput) {
            # Silent mode: only update status line on same line, don't show individual messages
            if ($shouldUpdateStatus) {
                Write-BuildStatus -Errors $errors -Warnings $warnings -Info $infoCount
                $lastStatusUpdate = $now
            }
        }
        else {
            # Verbose mode: clear status line, print message, then write status on new line
            # The status line will be overwritten by next iteration
            Write-BuildStatus -ClearLine
            Write-ColoredLine -Line $line -Type $lineType
            Write-BuildStatus -Errors $errors -Warnings $warnings -Info $infoCount
        }
    }
    
     # Final status update to ensure accurate counts are displayed
    Write-BuildStatus -Errors $errors -Warnings $warnings -Info $infoCount
    
    # Get exit code
    $buildExitCode = $LASTEXITCODE
    
    # In silent mode, only show errors (not warnings)
    # In verbose mode, errors and warnings were already shown during build
    if ($SilenceOutput) {
        Write-BuildOutput -Output $stdout -IncludeWarnings:$false
    }
    
    if ($errors -gt 0 -or $warnings -gt 0) {
        Write-Host "Build Summary: $errors error(s), $warnings warning(s)" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "Yellow" })
    }
    
    # BR.AS.Build.exe return codes (from B&R documentation):
    # 0 = No errors or warnings (success)
    # 1 = Warnings only (build succeeded, RUC package created)
    # 3 = Build error (build failed)
    # Exit codes 0 and 1 both indicate successful build (RUC package available for transfer)
    $buildSucceeded = $buildExitCode -in @(0, 1)
    $effectiveExitCode = if ($buildSucceeded) { 0 } else { $buildExitCode }
    
    return [BuildResult]::new($configName, $effectiveExitCode, $errors, $warnings)
}

function Get-PVITransferErrorMessage {
    <#
    .SYNOPSIS
        Returns human-readable error message for PVITransfer exit codes
    .NOTES
        PVITransfer (Runtime Utility Center) return codes from B&R documentation
    #>
    param([int]$ExitCode)
    
    switch ($ExitCode) {
        0       { return $null }  # Success
        4808    { return "PVI error: No connection available to the PLC. Is ARsim/PLC running?" }
        28320   { return "File not found (RUC package or PIL file)" }
        28321   { return "No file name specified" }
        28324   { return "Module not found" }
        28325   { return "Syntax error in command line" }
        default { return "Unknown transfer error (code: $ExitCode)" }
    }
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
    
     # PVITransfer is invoked as: PVITransfer.exe -silent <PIL file path>
    $transferArgs = @("-silent", $PILFile)
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
    
    # Provide helpful error message based on exit code
    $errorMsg = Get-PVITransferErrorMessage -ExitCode $process.ExitCode
    if ($errorMsg) {
        Write-Host $errorMsg -ForegroundColor Red
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
    # Use PVI bundled with the same AS version to ensure RUC package compatibility
    $pviPath = Get-PVIPath -ASPath $asPath
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
        Write-Step "Cleaning all build artifacts..."
        
        # Use BR.AS.Build.exe -cleanAll for each configuration
        foreach ($config in $configsToBuild) {
            Write-Host "  Cleaning configuration: $($config.Name)..."
            $cleanArgs = @(
                "`"$projectFile`"",
                "-c", $config.Name,
                "-cleanAll"
            )
            $cleanResult = Start-Process -FilePath $buildExe -ArgumentList $cleanArgs -Wait -PassThru -NoNewWindow
            if ($cleanResult.ExitCode -ne 0) {
                Write-Warning "Clean returned exit code: $($cleanResult.ExitCode)"
            }
        }
        
        
        Write-Success "Clean completed successfully"
    }
    
    "Build" {
        foreach ($config in $configsToBuild) {
            $result = Invoke-Build -BuildExe $buildExe -ProjectFile $projectFile -Config $config `
                -TempPath $tempPath -OutputPath $outputPath -Clean $false -Rebuild $false -SilenceOutput $SilenceOutputBool
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
                -TempPath $tempPath -OutputPath $outputPath -Clean (-not $NoClean) -Rebuild $true -SilenceOutput $SilenceOutputBool
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
        foreach ($config in $configsToBuild) {
            $result = Invoke-Build -BuildExe $buildExe -ProjectFile $projectFile -Config $config `
                -TempPath $tempPath -OutputPath $outputPath -Clean $false -Rebuild $false -SilenceOutput $SilenceOutputBool
            $buildResults += $result
            
            if ($result.ExitCode -ne 0) {
                $exitCode = $result.ExitCode
                Write-Failure "Build failed. Transfer skipped."
                break
            }
        }
        
        # Transfer if build succeeded
        if ($exitCode -eq 0) {
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
            
            $exitCode = Invoke-Transfer -TransferExe $transferExe -PILFile $pilToUse
            
            if ($exitCode -eq 0) {
                Write-Success "Transfer completed successfully"
            }
            else {
                Write-Failure "Transfer failed with exit code: $exitCode"
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
