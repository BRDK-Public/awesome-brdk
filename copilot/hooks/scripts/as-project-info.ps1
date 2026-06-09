# Requires PowerShell 5.1+
# SessionStart hook: extract B&R Automation Studio project metadata and emit
# additionalContext via stdout so the agent has accurate project facts upfront.

$ErrorActionPreference = 'Stop'
$workspace = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }

function Get-XmlAttr {
    param($Node, [string]$Name)
    if ($null -ne $Node -and $null -ne $Node.Attributes) {
        $a = $Node.Attributes[$Name]
        if ($a) { return $a.Value }
    }
    return $null
}

function Read-Xml {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try {
        $x = New-Object System.Xml.XmlDocument
        $x.Load($Path)
        return $x
    } catch { return $null }
}

$result = [ordered]@{
    AS = $null
    Project = $null
    TechnologyPackages = @{}
    Configurations = @()
}

# --- .apj file ---
$apj = Get-ChildItem -Path $workspace -Filter *.apj -File -ErrorAction SilentlyContinue | Select-Object -First 1
if ($apj) {
    $result.Project = $apj.BaseName
    $apjXml = Read-Xml $apj.FullName
    if ($apjXml) {
        $pi = $apjXml.SelectSingleNode("//processing-instruction('AutomationStudio')")
        if ($pi) {
            if ($pi.Value -match 'Version="([^"]+)"')        { $result.AS = @{ Version = $matches[1] } }
            if ($pi.Value -match 'WorkingVersion="([^"]+)"') { $result.AS.WorkingVersion = $matches[1] }
        }
        $proj = $apjXml.DocumentElement
        if ($proj) {
            $result.ProjectVersion = (Get-XmlAttr $proj 'Version')
            $result.Edition = (Get-XmlAttr $proj 'Edition')
        }
        $tp = $apjXml.SelectSingleNode("//*[local-name()='TechnologyPackages']")
        if ($tp) {
            foreach ($pkg in $tp.ChildNodes) {
                if ($pkg.NodeType -ne 'Element') { continue }
                $ver = Get-XmlAttr $pkg 'Version'
                if (-not $ver) {
                    # Sub-package versions (e.g. Acp10Arnc0 has Acp10_MC etc.)
                    $sub = @{}
                    foreach ($a in $pkg.Attributes) { $sub[$a.Name] = $a.Value }
                    $result.TechnologyPackages[$pkg.LocalName] = $sub
                } else {
                    $result.TechnologyPackages[$pkg.LocalName] = $ver
                }
            }
        }
    }
}

# --- Per-configuration scan ---
$physical = Join-Path $workspace 'Physical'
if (Test-Path -LiteralPath $physical) {
    $configDirs = Get-ChildItem -Path $physical -Directory -ErrorAction SilentlyContinue
    foreach ($cfgDir in $configDirs) {
        $cfg = [ordered]@{
            Name = $cfgDir.Name
            Cpu = $null
            CpuVersion = $null
            PlcIp = $null
            HmiPanel = $null
            HmiIp = $null
            OpcUaPort = $null
            OpcUaSecurityMode = $null
            MappViewPort = $null
            MappViewProtocol = $null
            VisuIds = @()
            StartPage = $null
            MappViewUrl = $null
        }

        # Hardware.hw
        $hw = Join-Path $cfgDir.FullName 'Hardware.hw'
        $hwXml = Read-Xml $hw
        if ($hwXml) {
            foreach ($m in $hwXml.GetElementsByTagName('Module')) {
                $type = Get-XmlAttr $m 'Type'
                # CPU detection: pattern X20CPxxxx or X90CPxxxx etc.
                if (-not $cfg.Cpu -and $type -match '^(X\d+CP|X90CP|APC|PPC|5PC)') {
                    $cfg.Cpu = $type
                    $cfg.CpuVersion = Get-XmlAttr $m 'Version'
                    foreach ($p in $m.GetElementsByTagName('Parameter')) {
                        if ((Get-XmlAttr $p 'ID') -eq 'InternetAddress') {
                            $cfg.PlcIp = Get-XmlAttr $p 'Value'; break
                        }
                    }
                }
                # First Power Panel found
                if (-not $cfg.HmiPanel -and $type -match '^(6PPT|6PFT|6PPC|4PP|5PP)') {
                    $cfg.HmiPanel = $type
                    foreach ($p in $m.GetElementsByTagName('Parameter')) {
                        if ((Get-XmlAttr $p 'ID') -eq 'InternetAddress') {
                            $cfg.HmiIp = Get-XmlAttr $p 'Value'; break
                        }
                    }
                }
            }
        }

        $cpuDir = Join-Path $cfgDir.FullName $cfgDir.Name
        if (Test-Path -LiteralPath $cpuDir) {
            # OPC UA port
            $uaCfg = Join-Path $cpuDir 'Connectivity\OpcUaCs\UaCsConfig.uacfg'
            $uaXml = Read-Xml $uaCfg
            if ($uaXml) {
                foreach ($p in $uaXml.GetElementsByTagName('Property')) {
                    switch (Get-XmlAttr $p 'ID') {
                        'TcpPort' { $cfg.OpcUaPort = Get-XmlAttr $p 'Value' }
                    }
                }
                foreach ($s in $uaXml.GetElementsByTagName('Selector')) {
                    if ((Get-XmlAttr $s 'ID') -eq 'SecurityMode') {
                        $cfg.OpcUaSecurityMode = Get-XmlAttr $s 'Value'
                    }
                }
            }

            # mappView port + protocol
            $mvCfg = Join-Path $cpuDir 'mappView\Config.mappviewcfg'
            $mvXml = Read-Xml $mvCfg
            if ($mvXml) {
                foreach ($s in $mvXml.GetElementsByTagName('Selector')) {
                    if ((Get-XmlAttr $s 'ID') -eq 'WebServerProtocol') {
                        $proto = Get-XmlAttr $s 'Value'
                        $cfg.MappViewProtocol = if ($proto -eq '2') { 'https' } else { 'http' }
                        foreach ($pp in $s.GetElementsByTagName('Property')) {
                            if ((Get-XmlAttr $pp 'ID') -eq 'WebServerPort') {
                                $cfg.MappViewPort = Get-XmlAttr $pp 'Value'
                            }
                        }
                    }
                }
            }

            # Visu IDs and start page from .vis file(s)
            $visFiles = Get-ChildItem -Path (Join-Path $cpuDir 'mappView') -Filter *.vis -File -ErrorAction SilentlyContinue
            foreach ($v in $visFiles) {
                $vXml = Read-Xml $v.FullName
                if (-not $vXml) { continue }
                $vid = Get-XmlAttr $vXml.DocumentElement 'id'
                if ($vid) { $cfg.VisuIds += $vid }
                $sp = $vXml.SelectSingleNode("//*[local-name()='StartPage']")
                if ($sp -and -not $cfg.StartPage) {
                    $cfg.StartPage = Get-XmlAttr $sp 'pageRefId'
                }
            }

            if ($cfg.MappViewPort -and $cfg.VisuIds.Count -gt 0) {
                $plcHost = if ($cfg.PlcIp) { $cfg.PlcIp } else { 'localhost' }
                $proto = if ($cfg.MappViewProtocol) { $cfg.MappViewProtocol } else { 'http' }
                $cfg.MappViewUrl = "${proto}://${plcHost}:$($cfg.MappViewPort)/index.html?visuId=$($cfg.VisuIds[0])"
            }
        }

        $result.Configurations += $cfg
    }
}

# --- Render compact markdown for the agent ---
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("## AS Project Snapshot (auto-injected on session start)")
$lines.Add("")
if ($result.Project) { $lines.Add("- **Project:** ``$($result.Project)``") }
if ($result.AS) {
    $asLine = "- **Automation Studio:** $($result.AS.Version)"
    if ($result.AS.WorkingVersion) { $asLine += " (WorkingVersion $($result.AS.WorkingVersion))" }
    $major = if ($result.AS.Version -match '^(\d+)') { $matches[1] } else { '?' }
    $asLine += " -- **AS" + $major + "** generation"
    $lines.Add($asLine)
}
if ($result.Edition)        { $lines.Add("- **Edition:** $($result.Edition)") }
if ($result.ProjectVersion) { $lines.Add("- **Project version:** $($result.ProjectVersion)") }

if ($result.TechnologyPackages.Count -gt 0) {
    $lines.Add("")
    $lines.Add("### Technology packages")
    foreach ($k in $result.TechnologyPackages.Keys | Sort-Object) {
        $v = $result.TechnologyPackages[$k]
        if ($v -is [hashtable]) {
            $parts = @()
            foreach ($sk in $v.Keys) { $parts += "$sk=$($v[$sk])" }
            $lines.Add("- **${k}:** $($parts -join ', ')")
        } else {
            $lines.Add("- **${k}:** $v")
        }
    }
    # Quick capability summary
    $caps = @()
    if ($result.TechnologyPackages.ContainsKey('Acp10Arnc0')) { $caps += 'ACP10 motion' }
    if ($result.TechnologyPackages.ContainsKey('mappMotion')) { $caps += 'mappMotion' }
    if ($result.TechnologyPackages.ContainsKey('mappView'))   { $caps += 'mappView HMI' }
    if ($result.TechnologyPackages.ContainsKey('mappServices')){ $caps += 'mappServices' }
    if ($result.TechnologyPackages.ContainsKey('mappSafety')) { $caps += 'mappSafety' }
    if ($result.TechnologyPackages.ContainsKey('OpcUaCs'))    { $caps += 'OPC UA C/S' }
    if ($caps.Count -gt 0) { $lines.Add(""); $lines.Add("**Stack:** " + ($caps -join ' + ')) }
}

foreach ($cfg in $result.Configurations) {
    $lines.Add("")
    $lines.Add("### Configuration: ``$($cfg.Name)``")
    if ($cfg.Cpu)              { $lines.Add("- **CPU:** $($cfg.Cpu) (HW ver $($cfg.CpuVersion))") }
    if ($cfg.PlcIp)            { $lines.Add("- **PLC IP:** $($cfg.PlcIp)") }
    if ($cfg.HmiPanel)         { $lines.Add("- **HMI panel:** $($cfg.HmiPanel)" + $(if ($cfg.HmiIp) { " @ $($cfg.HmiIp)" } else { '' })) }
    if ($cfg.OpcUaPort)        { $lines.Add("- **OPC UA:** port $($cfg.OpcUaPort)" + $(if ($cfg.OpcUaSecurityMode) { " (SecurityMode=$($cfg.OpcUaSecurityMode))" } else { '' })) }
    if ($cfg.MappViewPort)     { $lines.Add("- **mappView:** $($cfg.MappViewProtocol)://`<host`>:$($cfg.MappViewPort)") }
    if ($cfg.VisuIds.Count -gt 0) { $lines.Add("- **Visu IDs:** " + ($cfg.VisuIds -join ', ')) }
    if ($cfg.StartPage)        { $lines.Add("- **Start page:** $($cfg.StartPage)") }
    if ($cfg.MappViewUrl)      { $lines.Add("- **HMI URL (PLC):** $($cfg.MappViewUrl)") }
    if ($cfg.MappViewPort -and $cfg.VisuIds.Count -gt 0) {
        $lines.Add("- **HMI URL (ARsim):** http://localhost:$($cfg.MappViewPort)/index.html?visuId=$($cfg.VisuIds[0])")
    }
}

$additionalContext = ($lines -join "`n")

$out = @{
    hookSpecificOutput = @{
        hookEventName     = 'SessionStart'
        additionalContext = $additionalContext
    }
} | ConvertTo-Json -Depth 6 -Compress

Write-Output $out
exit 0
