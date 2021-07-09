$d4n = Invoke-RestMethod -Uri "https://raw.datafornerds.io/ms/mswin/buildnumbers.json"

$props = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$osVer = ([string]$props.CurrentMajorVersionNumber + '.' + [string]$props.CurrentMinorVersionNumber + '.' + [string]$props.CurrentBuildNumber + '.' + [string]$props.UBR)

$myBuild = $d4n.data | Where-Object { $_.Win10Version -eq $osVer }

Write-Host "You are running $osVer with Update $($myBuild.Article)"
Write-Host "Your patch level was released by Microsoft on $($myBuild.ReleaseDate)"

$patchDiff = New-TimeSpan -Start (Get-Date $myBuild.ReleaseDate) -End (Get-Date)

If($patchDiff.TotalDays -ge 30) {
    Write-Host "It might be time to look for an updated patch!" -ForegroundColor Red
} else {
    Write-Host "You're patch is recent enough." -ForegroundColor Green
}
