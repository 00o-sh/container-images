# Sysprep the Windows installation
# This is the final step before capturing the image

Write-Host "Preparing to run Sysprep..."

# Disable auto-logon before sysprep
Write-Host "Clearing auto-logon settings..."
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoAdminLogon" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultUserName" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultPassword" -ErrorAction SilentlyContinue

# Remove Packer-specific WinRM configuration
Write-Host "Resetting WinRM configuration..."
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value False -ErrorAction SilentlyContinue
Set-Item WSMan:\localhost\Service\Auth\Basic -Value False -ErrorAction SilentlyContinue

# Clear WinRM listener (will be recreated on first boot)
# winrm delete winrm/config/Listener?Address=*+Transport=HTTP 2>$null

# Final cleanup
Write-Host "Final cleanup before sysprep..."
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# Zero out free space for better compression (optional, takes time)
# Uncomment for smaller final image:
# Write-Host "Zeroing free space for better compression..."
# $volume = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
# $freeSpace = $volume.FreeSpace
# $zeroFile = "C:\zero.tmp"
# $stream = [System.IO.File]::Create($zeroFile)
# try {
#     $zeros = New-Object byte[] (1MB)
#     while ($stream.Length -lt ($freeSpace - 100MB)) {
#         $stream.Write($zeros, 0, $zeros.Length)
#     }
# } finally {
#     $stream.Close()
#     Remove-Item $zeroFile -Force
# }

Write-Host "Running Sysprep..."
Write-Host "The system will shut down after sysprep completes."

# Run sysprep with generalize and OOBE
# /generalize - Removes machine-specific information
# /oobe - Restarts to Out-of-Box Experience
# /shutdown - Shuts down after completion (required for image capture)
# /quiet - No UI
# /mode:vm - Optimizes for VM deployment (faster, skips hardware detection)

$sysprepPath = "$env:SystemRoot\System32\Sysprep\Sysprep.exe"
$sysprepArgs = "/generalize /oobe /shutdown /quiet /mode:vm"

Write-Host "Executing: $sysprepPath $sysprepArgs"

# Create unattend file for sysprep to use on next boot (minimal OOBE)
$sysprepUnattend = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideLocalAccountScreen>true</HideLocalAccountScreen>
        <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <ProtectYourPC>3</ProtectYourPC>
        <NetworkLocation>Work</NetworkLocation>
      </OOBE>
      <TimeZone>UTC</TimeZone>
    </component>
    <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <InputLocale>en-US</InputLocale>
      <SystemLocale>en-US</SystemLocale>
      <UILanguage>en-US</UILanguage>
      <UserLocale>en-US</UserLocale>
    </component>
  </settings>
</unattend>
"@

$sysprepUnattendPath = "C:\Windows\System32\Sysprep\unattend.xml"
$sysprepUnattend | Out-File -FilePath $sysprepUnattendPath -Encoding UTF8

# Start sysprep
Start-Process -FilePath $sysprepPath -ArgumentList "/generalize", "/oobe", "/shutdown", "/quiet", "/mode:vm", "/unattend:$sysprepUnattendPath" -Wait

# Note: The script won't reach here as sysprep will shut down the machine
Write-Host "Sysprep initiated. System will shut down momentarily."
