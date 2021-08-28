#Import-Module $env:SyncroModule


function Set-WakeEnabled
{
<#
.SYNOPSIS

Set WoL on nic

Author: Jan-Henrik Damaschke (@jandamaschke)
License: BSD 3-Clause
Required Dependencies: None
Optional Dependencies: None

.DESCRIPTION

Set Wake on Lan (WOL) settings for specific network interface card

.PARAMETER InterfaceName

Specifies the name of the interface where WoL setting should be changed

.PARAMETER WakeEnabled

Specifies if WoL should be enabled or disabled

.EXAMPLE

PS C:\> Set-WakeEnabled -InterfaceName Ethernet -WakeEnabled $true

.LINK

http://itinsights.org/
#>

[CmdletBinding()] Param(
        [Parameter(Mandatory = $True, ParameterSetName="InterfaceName")]
        [String]
        $InterfaceName,

        [Parameter(Mandatory = $True)]
        [String]
        $WakeEnabled,

        [Parameter(Mandatory = $True, ParameterSetName="ConnectionID")]
        [String]
        $NetConnectionID
)

    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
        Break
    }

    $nicsWakeEnabled = Get-CimInstance -ClassName MSPower_DeviceWakeEnable -Namespace root/wmi
    $nics = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object NetEnabled -eq $true

    if ($InterfaceName){
        $nic = $nics | Where-Object Name -eq $InterfaceName
    }
    else {
        $nic = $nics | Where-Object NetConnectionID -eq $NetConnectionID
    }

    $nicWakeEnabled = $nicsWakeEnabled | Where-Object InstanceName -like "*$($nic.PNPDeviceID)*"
    
    $enabled = $nicWakeEnabled.Enable

    if (!($enabled -and $WakeEnabled)){
        Set-CimInstance $nicWakeEnabled -Property @{Enable=$enabled}
    }
}

$adapter = Get-NetAdapter | Select -ExpandProperty Name
$adapter | foreach-object {
    Set-WakeEnabled -InterfaceName $_ -WakeEnabled $true
}


$PPNuGet = Get-PackageProvider -ListAvailable | Where-Object { $_.Name -eq "Nuget" }
if (!$PPNuget) {
    Write-Host "Installing Nuget provider" -foregroundcolor Green
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
}

$PSGallery = Get-PSRepository -Name PsGallery
if (!$PSGallery) {
    Write-Host "Installing PSGallery" -foregroundcolor Green
    Set-PSRepository -InstallationPolicy Trusted -Name PSGallery
}

$PsGetVersion = (get-module PowerShellGet).version
if ($PsGetVersion -lt [version]'2.0') {
    Write-Host "Installing latest version of PowerShellGet provider" -foregroundcolor Green
    install-module PowerShellGet -MinimumVersion 2.2 -Force
    Write-Host "Reloading Modules" -foregroundcolor Green
    Remove-Module PowerShellGet -Force
    Remove-module PackageManagement -Force
    Import-Module PowerShellGet -MinimumVersion 2.2 -Force
    Write-Host "Updating PowerShellGet" -foregroundcolor Green
    Install-Module -Name PowerShellGet -MinimumVersion 2.2.3 -force
    #Rmm-Alert "You must rerun the script to succesfully get the WOL status. PowerShellGet was found out of date." -ForegroundColor red
}

Write-Host "Checking Manufacturer" -foregroundcolor Green
$Manufacturer = (Get-WmiObject -Class:Win32_ComputerSystem).Manufacturer

if ($Manufacturer -like "*Dell*") {
    Write-Host "Manufacturer is Dell. Installing Module and trying to get WOL state" -foregroundcolor Green
    Write-Host "Installing Dell Bios Provider if needed" -foregroundcolor Green
    $Mod = Get-Module DellBIOSProvider
    if (!$mod) {
        Install-Module -Name DellBIOSProvider -Force
    }
    import-module DellBIOSProvider
    try { 
        $WOLMonitor = get-item -Path "DellSmBios:\PowerManagement\WakeOnLan" -ErrorAction SilentlyContinue
        if($WOLMonitor.currentvalue -eq "LanOnly"){ $WOLState = "Healthy"}
    }
    catch {
        write-host "an error occured. Could not get WOL setting."
    }
}

if ($Manufacturer -like "*HP*" -or $Manufacturer -like "*Hewlett*") {
    Write-Host "Manufacturer is HP. Installing module and trying to get WOL State." -foregroundcolor Green
    Write-Host "Installing HP Provider if needed." -foregroundcolor Green
    $Mod = Get-Module HPCMSL
    if (!$mod) {
        Install-Module -Name HPCMSL -Force -AcceptLicense
    }
    import-module HPCMSL
    try { 
        $WolTypes = get-hpbiossettingslist | Where-Object { $_.Name -like "*Wake On Lan*" }
        $WOLState = ForEach ($WolType in $WolTypes) {
            write-host "Setting WOL Type: $($WOLType.Name)"
            get-HPBIOSSettingValue -name $($WolType.name) -ErrorAction Stop 
        }
    }
    catch {
        write-host "an error occured. Could not find WOL state"
    }
}

if ($Manufacturer -like "*Lenovo*") {
    Write-Host "Manufacturer is Lenovo. Trying to get via WMI" -foregroundcolor Green
    try { 
        Write-Host "Getting BIOS." -foregroundcolor Green
        $currentSetting = (Get-WmiObject -ErrorAction Stop -class "Lenovo_BiosSetting" -namespace "root\wmi") | Where-Object { $_.CurrentSetting -ne "" }
        $WOLStatus = $currentSetting.currentsetting | ConvertFrom-Csv -Delimiter "," -Header "Setting", "Status" | Where-Object { $_.setting -eq "Wake on lan" }
        $WOLStatus = $WOLStatus.status -split ";"
        if ($WOLStatus[0] -eq "Primary") { $WOLState = "Healthy" }
    }
    catch {
        write-host "an error occured. Could not find WOL state" 
    }
}

$NicsWithWake = Get-CimInstance -ClassName "MSPower_DeviceWakeEnable" -Namespace "root/wmi" | Where-Object { $_.Enable -eq $False }
if (!$NicsWithWake) {
    $NICWOL = "Healthy - All NICs enabled for WOL within the OS." 
} 
else {
#Rmm-Alert -Category 'WOL (OS)' -Body "Unhealthy - NIC does not have WOL enabled inside of the OS." 
Write-Host "Unhealthy - NIC does not have WOL enabled inside of the OS." 
}

if (!$WOLState) { 
   #Rmm-Alert -Category 'WOL (BIOS)' -Body "Unhealthy - Could not find WOL state" 
   Write-Host "Unhealthy - Could not find WOL state" 
}