<#
.SYNOPSIS
    Exports a root certificate from Windows and installs it into a WSL distribution.

.DESCRIPTION
    This script searches for a certificate in the Windows Certificate Store matching the provided subject,
    exports it, and then installs it into the specified WSL distribution's trusted certificate store.
    Useful for corporate environments with SSL inspection (e.g., Zscaler).

.PARAMETER CertSubject
    The subject name of the certificate to find. Default is '*Zscaler Root CA*'.

.PARAMETER Distro
    The WSL distribution to install the certificate into. If omitted, uses the default distribution.

.EXAMPLE
    .\install-certs-wsl.ps1
    Installs Zscaler certificate into default WSL distro.

.EXAMPLE
    .\install-certs-wsl.ps1 -Distro Ubuntu-22.04
    Installs Zscaler certificate into Ubuntu-22.04.
#>
param(
    [string]$CertSubject = '*Zscaler Root CA*',
    [string]$Distro
)

$ErrorActionPreference = "Stop"

Write-Host "Searching for certificate matching '$CertSubject' in Cert:\LocalMachine\Root..."
$certs = @(Get-ChildItem -path Cert:\LocalMachine\Root -Recurse | Where-Object {$_.Subject -like $CertSubject})

if ($certs.Count -eq 0) {
    Write-Warning "Certificate not found in LocalMachine\Root. Checking CurrentUser\Root..."
    $certs = @(Get-ChildItem -path Cert:\CurrentUser\Root -Recurse | Where-Object {$_.Subject -like $CertSubject})
}

if ($certs.Count -eq 0) {
    Write-Error "Certificate matching '$CertSubject' not found."
    exit 1
}

if ($certs.Count -gt 1) {
    Write-Warning "Multiple certificates matching '$CertSubject' were found. Please select one to install:"
    for ($i = 0; $i -lt $certs.Count; $i++) {
        $c = $certs[$i]
        Write-Host "[$i] Subject: $($c.Subject) | Thumbprint: $($c.Thumbprint)"
    }

    $selection = Read-Host "Enter the index of the certificate to use (default is 0)"
    if ([string]::IsNullOrWhiteSpace($selection)) {
        $selectedIndex = 0
    } elseif (-not [int]::TryParse($selection, [ref]$selectedIndex)) {
        Write-Warning "Input '$selection' is not a valid number. Defaulting to index 0."
        $selectedIndex = 0
    } elseif ($selectedIndex -lt 0 -or $selectedIndex -ge $certs.Count) {
        Write-Warning "Index '$selectedIndex' is out of range. Defaulting to index 0."
        $selectedIndex = 0
    }

    $cert = $certs[$selectedIndex]
} else {
    $cert = $certs[0]
}
Write-Host "Found certificate: $($cert.Subject)"
Write-Host "Thumbprint: $($cert.Thumbprint)"

$tempFileName = "wsl_cert_export.cer"
$tempFilePath = Join-Path $env:USERPROFILE $tempFileName
Write-Host "Exporting certificate to $tempFilePath..."
Export-Certificate -Cert $cert -Type cer -FilePath $tempFilePath -Force | Out-Null

# Construct WSL command
$wslArgs = @()
if (-not [string]::IsNullOrEmpty($Distro)) {
    $wslArgs += "-d", $Distro
}
$wslArgs += "-u", "root"
$wslArgs += "-e", "bash", "-c"

# WSL path to the exported file
# Use wslpath to convert the Windows path to the WSL path correctly
# This handles different mount points and username mismatches
$wslPathArgs = @()
if (-not [string]::IsNullOrEmpty($Distro)) {
    $wslPathArgs += "-d", $Distro
}
$wslPathArgs += "-e", "wslpath", "-u", "$tempFilePath"

Write-Host "Resolving WSL path for $tempFilePath..."
$wslSourcePath = (& wsl.exe $wslPathArgs).Trim()

if (-not $wslSourcePath) {
    Write-Error "Failed to resolve WSL path. Ensure WSL is working."
    exit 1
}

Write-Host "WSL Source Path: $wslSourcePath"

$targetCrtPath = "/usr/local/share/ca-certificates/custom-corporate-root.crt"

Write-Host "Installing certificate in WSL..."

# Command to run inside WSL:
# 1. Convert DER (.cer) to PEM (.crt) and place it in /usr/local/share/ca-certificates/
# 2. Run update-ca-certificates to update /etc/ssl/certs/
$bashCommand = "openssl x509 -inform der -in '$wslSourcePath' -out '$targetCrtPath' && update-ca-certificates"

# Execute
try {
    $process = Start-Process -FilePath "wsl.exe" -ArgumentList ($wslArgs + $bashCommand) -PassThru -Wait -NoNewWindow

    if ($process.ExitCode -eq 0) {
        Write-Host "Certificate installed successfully."
    } else {
        Write-Error "Failed to install certificate in WSL. Exit code: $($process.ExitCode)"
    }
} finally {
    Write-Host "Cleaning up..."
    if (Test-Path $tempFilePath) {
        Remove-Item -Path $tempFilePath -Force
    }
}
Write-Host "Done."
