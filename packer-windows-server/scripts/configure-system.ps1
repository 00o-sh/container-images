# Configure Windows Server for KubeVirt deployment
# This script applies system configurations before sysprep

Write-Host "Configuring Windows Server for KubeVirt..."

# Disable hibernation (saves disk space)
Write-Host "Disabling hibernation..."
powercfg -h off

# Disable automatic Windows updates (for template images)
Write-Host "Configuring Windows Update settings..."
$WUSettings = (New-Object -ComObject Microsoft.Update.AutoUpdate)
try {
    $WUSettings.EnableService()
} catch {
    Write-Host "Note: Could not configure Windows Update service"
}

# Set power plan to High Performance
Write-Host "Setting power plan to High Performance..."
$powerPlan = Get-CimInstance -Namespace root\cimv2\power -ClassName Win32_PowerPlan | Where-Object { $_.ElementName -eq "High Performance" }
if ($powerPlan) {
    powercfg /setactive $powerPlan.InstanceID.Split('"')[1]
    Write-Host "Power plan set to High Performance"
}

# Enable Remote Desktop
Write-Host "Enabling Remote Desktop..."
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Disable Windows Defender real-time protection (optional, for performance)
# Uncomment if needed:
# Write-Host "Configuring Windows Defender..."
# Set-MpPreference -DisableRealtimeMonitoring $true

# Clean up temp files
Write-Host "Cleaning up temporary files..."
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# Clear event logs (optional, for smaller image)
Write-Host "Clearing event logs..."
wevtutil el | ForEach-Object { wevtutil cl $_ 2>$null }

# Optimize disk
Write-Host "Optimizing disk..."
Optimize-Volume -DriveLetter C -Defrag -Verbose

Write-Host "System configuration complete."
