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

$cert = $certs[0]
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

# Check if openssl is installed in the WSL distribution
Write-Host "Verifying openssl is available..."
$opensslCheckArgs = @()
if (-not [string]::IsNullOrEmpty($Distro)) {
    $opensslCheckArgs += "-d", $Distro
}
$opensslCheckArgs += "-e", "bash", "-c", "command -v openssl"

$opensslPath = (& wsl.exe $opensslCheckArgs 2>$null).Trim()

if (-not $opensslPath) {
    Write-Error @"
openssl is not installed in the WSL distribution.
Please install openssl in your WSL distribution before running this script.

For Ubuntu/Debian-based distributions, run:
    wsl -d $Distro -u root -e bash -c "apt-get update && apt-get install -y openssl"

For other distributions, use the appropriate package manager.
"@
    exit 1
}

Write-Host "openssl found at: $opensslPath"

# Command to run inside WSL:
# 1. Convert DER (.cer) to PEM (.crt) and place it in /usr/local/share/ca-certificates/
# 2. Run update-ca-certificates to update /etc/ssl/certs/
$bashCommand = "openssl x509 -inform der -in '$wslSourcePath' -out '$targetCrtPath' && update-ca-certificates"

# Execute
$process = Start-Process -FilePath "wsl.exe" -ArgumentList ($wslArgs + $bashCommand) -PassThru -Wait -NoNewWindow

if ($process.ExitCode -eq 0) {
    Write-Host "Certificate installed successfully."
} else {
    Write-Error "Failed to install certificate in WSL. Exit code: $($process.ExitCode)"
}

Write-Host "Cleaning up..."
if (Test-Path $tempFilePath) {
    Remove-Item -Path $tempFilePath -Force
}

Write-Host "Done."
