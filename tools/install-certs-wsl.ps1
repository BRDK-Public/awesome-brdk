<#
.SYNOPSIS
    Exports a root certificate from Windows and installs it into a WSL distribution.

.DESCRIPTION
    This script searches for a certificate in the Windows Certificate Store matching the provided subject,
    exports it, and then installs it into the specified WSL distribution's trusted certificate store.
    Useful for corporate environments with SSL inspection (e.g., Zscaler).

.PARAMETER CertSubject
    The subject name(s) of the certificate(s) to find. Default is @('*Zscaler Root CA*', '*ABB*').
    Can accept multiple patterns as an array.

.PARAMETER Distro
    The WSL distribution to install the certificate into. If omitted, uses the default distribution.

.EXAMPLE
    .\install-certs-wsl.ps1
    Installs Zscaler and ABB certificates into default WSL distro.

.EXAMPLE
    .\install-certs-wsl.ps1 -Distro Ubuntu-22.04
    Installs Zscaler and ABB certificates into Ubuntu-22.04.

.EXAMPLE
    .\install-certs-wsl.ps1 -CertSubject '*Zscaler*'
    Installs only Zscaler certificates into default WSL distro.
#>
param(
    [string[]]$CertSubject = @('*Zscaler Root CA*', '*ABB*'),
    [string]$Distro
)

$ErrorActionPreference = "Stop"

Write-Host "Searching for certificates matching patterns: $($CertSubject -join ', ') in Cert:\LocalMachine\Root..."
$certs = @(Get-ChildItem -path Cert:\LocalMachine\Root -Recurse | Where-Object {
    foreach ($pattern in $CertSubject) {
        if ($_.Subject -like $pattern) { return $true }
    }
})

if ($certs.Count -eq 0) {
    Write-Warning "Certificate not found in LocalMachine\Root. Checking CurrentUser\Root..."
    $certs = @(Get-ChildItem -path Cert:\CurrentUser\Root -Recurse | Where-Object {
        foreach ($pattern in $CertSubject) {
            if ($_.Subject -like $pattern) { return $true }
        }
    })
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
    Write-Host "[all] Install all certificates"

    $selection = Read-Host "Enter the index of the certificate to use, or 'all' (default is 0)"
    if ([string]::IsNullOrWhiteSpace($selection)) {
        $selectedCerts = @($certs[0])
    } elseif ($selection -eq 'all') {
        $selectedCerts = $certs
    } else {
        $selectedIndex = 0
        if (-not [int]::TryParse($selection, [ref]$selectedIndex)) {
            Write-Warning "Input '$selection' is not a valid number. Defaulting to index 0."
            $selectedIndex = 0
        } elseif ($selectedIndex -lt 0 -or $selectedIndex -ge $certs.Count) {
            Write-Warning "Index '$selectedIndex' is out of range. Defaulting to index 0."
            $selectedIndex = 0
        }
        $selectedCerts = @($certs[$selectedIndex])
    }
} else {
    $selectedCerts = @($certs[0])
}
Write-Host "Selected $($selectedCerts.Count) certificate(s) for installation."

# Check if openssl is installed in the WSL distribution (do this once before the loop)
Write-Host "Verifying openssl is available..."
$opensslCheckArgs = @()
if (-not [string]::IsNullOrEmpty($Distro)) {
    $opensslCheckArgs += "-d", $Distro
}
$opensslCheckArgs += "-e", "bash", "-c", "command -v openssl"

$opensslPath = (& wsl.exe $opensslCheckArgs 2>$null).Trim()

if (-not $opensslPath) {
    $distroFlag = if ([string]::IsNullOrEmpty($Distro)) { "" } else { "-d $Distro " }
    
    $errorMessage = @"
openssl is not installed in the WSL distribution.
Please install openssl in your WSL distribution before running this script.

Installation examples:
  Ubuntu/Debian: wsl ${distroFlag}-u root -e bash -c "apt-get update && apt-get install -y openssl"
  Alpine:        wsl ${distroFlag}-u root -e ash -c "apk add --no-cache openssl"
  openSUSE:      wsl ${distroFlag}-u root -e bash -c "zypper install -y openssl"
  RHEL/CentOS:   wsl ${distroFlag}-u root -e bash -c "dnf install -y openssl"

Use the appropriate command for your distribution.
"@
    throw $errorMessage
}

Write-Host "openssl found at: $opensslPath"

$tempFileName = "wsl_cert_export.cer"
$tempFilePath = Join-Path $env:USERPROFILE $tempFileName
$installedCount = 0

try {
    for ($certIndex = 0; $certIndex -lt $selectedCerts.Count; $certIndex++) {
        $cert = $selectedCerts[$certIndex]
        Write-Host "`n--- Certificate $($certIndex + 1) of $($selectedCerts.Count) ---"
        Write-Host "Subject: $($cert.Subject)"
        Write-Host "Thumbprint: $($cert.Thumbprint)"

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
            throw "Failed to resolve WSL path. Ensure WSL is working."
        }

        Write-Host "WSL Source Path: $wslSourcePath"

        # Use thumbprint in filename to make each cert unique
        $targetCrtPath = "/usr/local/share/ca-certificates/custom-corporate-root-$($cert.Thumbprint).crt"

        Write-Host "Installing certificate in WSL to $targetCrtPath..."

        # Execute openssl directly via wsl to avoid bash escaping issues
        $opensslArgs = @()
        if (-not [string]::IsNullOrEmpty($Distro)) {
            $opensslArgs += "-d", $Distro
        }
        $opensslArgs += "-u", "root", "--", "openssl", "x509", "-inform", "der", "-in", $wslSourcePath, "-out", $targetCrtPath

        $process = Start-Process -FilePath "wsl.exe" -ArgumentList $opensslArgs -PassThru -Wait -NoNewWindow

        if ($process.ExitCode -eq 0) {
            Write-Host "Certificate exported to WSL successfully."
            $installedCount++
        } else {
            Write-Warning "Failed to export certificate to WSL. Exit code: $($process.ExitCode)"
        }
    }

    # Run update-ca-certificates once after all certs are installed
    if ($installedCount -gt 0) {
        Write-Host "`nUpdating CA certificates in WSL..."
        $updateArgs = @()
        if (-not [string]::IsNullOrEmpty($Distro)) {
            $updateArgs += "-d", $Distro
        }
        $updateArgs += "-u", "root", "-e", "bash", "-c", "update-ca-certificates"

        $process = Start-Process -FilePath "wsl.exe" -ArgumentList $updateArgs -PassThru -Wait -NoNewWindow

        if ($process.ExitCode -eq 0) {
            Write-Host "$installedCount certificate(s) installed successfully."
        } else {
            Write-Error "Failed to update CA certificates in WSL. Exit code: $($process.ExitCode)"
        }
    }
}
finally {
    Write-Host "Cleaning up..."
    if (Test-Path $tempFilePath) {
        Remove-Item -Path $tempFilePath -Force
    }

    Write-Host "Done."
}
