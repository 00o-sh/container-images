# Install VirtIO Guest Tools
# This script installs the VirtIO guest tools MSI from the drivers ISO

Write-Host "Installing VirtIO Guest Tools..."

# Find the VirtIO drivers CD (should be drive E: or F:)
$virtioDrive = Get-Volume | Where-Object { $_.FileSystemLabel -like "virtio*" } | Select-Object -First 1

if ($virtioDrive) {
    $driveLetter = $virtioDrive.DriveLetter
    $msiPath = "${driveLetter}:\virtio-win-gt-x64.msi"

    if (Test-Path $msiPath) {
        Write-Host "Found VirtIO MSI at: $msiPath"
        Write-Host "Installing VirtIO guest tools..."

        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $msiPath, "/quiet", "/norestart" -Wait -PassThru

        if ($process.ExitCode -eq 0) {
            Write-Host "VirtIO guest tools installed successfully."
        } elseif ($process.ExitCode -eq 3010) {
            Write-Host "VirtIO guest tools installed successfully (reboot required)."
        } else {
            Write-Warning "VirtIO MSI installation returned exit code: $($process.ExitCode)"
        }
    } else {
        Write-Warning "VirtIO MSI not found at expected path: $msiPath"
        Write-Host "Available files on ${driveLetter}:"
        Get-ChildItem "${driveLetter}:\" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  $_" }
    }
} else {
    Write-Warning "VirtIO drivers ISO not found. Skipping guest tools installation."
    Write-Host "Available volumes:"
    Get-Volume | Format-Table -AutoSize
}

Write-Host "VirtIO installation script complete."
