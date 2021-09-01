Import-Module $env:SyncroModule
$DownloadLocation = "C:\Temp"
function Get-LatestDellCommand {
    $version = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/flcdrg/au-packages/master/dellcommandupdate/dellcommandupdate.nuspec" -UseBasicParsing
    $nuspec = [xml]$version.Content
    if ($nuspec.package.metadata.version -eq $software.Version ) {
        Write-Output "No updates to Dell Command found"
    }
}

function Install-DellCommand {
    Test-Choco
    $software = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\" | Get-ItemProperty
    if ([Environment]::Is64BitOperatingSystem) {
        $software += Get-ChildItem "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\" | Get-ItemProperty
    }
    
    #Readme: C:\Program Files (x86)\Dell\CommandUpdate\readme.txt
    $readme = $software | Where-Object { $_.DisplayName -like "*Dell Command*" }  | select-object -ExpandProperty Readme
    $readme = Test-Path $readme

    if (!$readme) {
        Write-Host "Install Dell Command"
        Start-Process -FilePath "$($SyncroChocoDir)cup.exe" -ArgumentList "dellcommandupdate -y" -Wait -NoNewWindow
        $dcu = Test-path "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe"
        if (!$dcu) {
            Write-Host "Failed to install Dell Command"
            Rmm-Alert -Category 'Syncro' -Body "Dell Command Not Installed"
        }
    }
    else {
        Write-Host "Dell Command Installed"
    }
}
function Test-Choco {
    $SyncroChocoDir = "C:\Program Files\RepairTech\Syncro\kabuto_app_manager\bin\"
    Test-Path $SyncroChocoDir
    if (!$SyncroChocoDir) {
        Rmm-Alert -Category 'Syncro' -Body "Chocolatey Not Installed"
        exit 1
    }
}

function Get-DellCommandInstalls {
    # Grab the registry uninstall keys to search against (x86 and x64)
    $software = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\" | Get-ItemProperty
    if ([Environment]::Is64BitOperatingSystem) {
        $software += Get-ChildItem "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\" | Get-ItemProperty
    }
    
    $software = $software | Where-Object { $_.DisplayName -like "*Dell Command*" } | Select-Object @{N = "DisplayName"; E = { $_.DisplayName } }, @{N = "UninstallString"; E = { $_.UninstallString } }, @{N = "Version"; E = { $_.DisplayVersion } }
    
    if ($software.Version -lt '4.3.0') {
        Start-Process "msiexec.exe" -ArgumentList "/x {5669AB71-1302-4412-8DA1-CB69CD7B7324} /qn" -Wait
        Start-Process "msiexec.exe" -ArgumentList "/x {4CD85DD3-A024-4409-A0F2-F70DE1E4A935} /qn" -Wait
        Start-Process "msiexec.exe" -ArgumentList "/x {4CCADC13-F3AE-454F-B724-33F6D4E52022} /qn" -Wait
        Start-Process "msiexec.exe" -ArgumentList "/x {9C4C51BE-CFFB-4400-91BE-43E8285AD207} /qn" -Wait
    }
    else {
        Write-Output "Dell Command Installed on the right version or above"
        Close-Rmm-Alert -Category "Potentially Unwanted Applications"
        Get-LatestDellCommand
    }
}


Install-DellCommand


Write-Output "Starting to look for updates"
start-process "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe" -ArgumentList "/scan -updateSeverity=critical,recommended -report=$DownloadLocation" -Wait -WindowStyle Hidden
[xml]$XMLReport = get-content "$DownloadLocation\DCUApplicableUpdates.xml" -ErrorAction SilentlyContinue
#We now remove the item, because we don't need it anymore, and sometimes fails to overwrite
remove-item "$DownloadLocation\DCUApplicableUpdates.xml" -Force -ErrorAction SilentlyContinue

$numofupdates = ($XMLReport.updates.update).count
if ($numofupdates -gt 0) {
    $AvailableUpdates = $XMLReport.updates.update
    $report = $AvailableUpdates | Select-Object "name", "version", "date", "urgency", "type" | Format-Table -Autosize | Out-String 
    $report



    $currentbiosversion = Get-WmiObject -Class Win32_BIOS | Select-Object -ExpandProperty SMBIOSBIOSVersion
    $newestbiosversion = ($XMLReport.updates.update | Where-Object { $_.type -eq "BIOS" }).version
    if ($null -eq $newestbiosversion) { 
        $newestbiosversion = "$currentbiosversion"
    }
    Write-Output "Current BIOS Version: $currentbiosversion"
    Write-Output "Newest BIOS Version: $newestbiosversion"
    #Rmm-Alert -Category 'DellFirmware' -Body "$report"
    if ($currentbiosversion -eq $newestbiosversion) {
        "BIOS version is current"
        Close-Rmm-Alert -Category 'DellBios'
    }
    else {
        "BIOS version is out of date"
        $DownloadLocation = "C:\Program Files\Dell\CommandUpdate"
        start-process "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe" -ArgumentList "/applyUpdates -autoSuspendBitLocker=enable -reboot=disable -updateType=bios" -Wait

        #Rmm-Alert -Category "Dell BIOS" -Body "BIOS version is out of date and automatic update failed"
    }
}