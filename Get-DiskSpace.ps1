#=============================================================================================================================
#
# Script Name:     Get-Diskspace.ps1
# Description:     Detects the free disk space on the clients
# Notes:           To be used as Intune Detection script
# Author:          James Barber
# Date:            20th June 2022
#=============================================================================================================================
$os = Get-CimInstance Win32_OperatingSystem
$systemDrive = Get-CimInstance Win32_LogicalDisk -Filter "deviceid='$($os.SystemDrive)'"
$PercentFree = ($systemDrive.FreeSpace/$systemDrive.Size) * 100
$PercentRounded = [math]::Truncate($PercentFree)
if ($PercentFree -le '10') {
    Write-Output "Low disk space. Free Space is $PercentRounded %"
    exit 1
}
else {
    Write-Output "Disk space is OK. Free Space is $PercentRounded %"
    exit 0
}