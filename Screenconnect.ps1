Import-Module $env:SyncroModule

# Replace this with YOUR screenconnect client service name
$serviceName = 'ScreenConnect Client ()'

# URL for ScreenConnect exe download
# add your url here and the first $c in my enviorment is Company Name or CustomProperty1 
$url = "&e=Access&y=Guest&t=&c=$name"

# Your syncro subdomain
$subdomain = ""

If (Get-Service $serviceName -ErrorAction SilentlyContinue) {
   If ((Get-Service $serviceName).Status -eq 'Running') {
   } Else {
       Write-Host "$serviceName found, but it is not running for some reason."
       write-host "starting $servicename"
       start-service $serviceName
   }
} Else {
   Write-Host "$serviceName not found - need to install"
   (new-object System.Net.WebClient).DownloadFile($url,'C:\windows\temp\sc.msi')
   msiexec.exe /i c:\windows\temp\sc.msi /quiet

}

$Keys = Get-ChildItem HKLM:\System\ControlSet001\Services
$Guid = "Null";
$Items = $Keys | Foreach-Object {Get-ItemProperty $_.PsPath }

    ForEach ($Item in $Items)
    {
        if ($item.PSChildName -like "*ScreenConnect Client*")
    {
    $SubKeyName = $Item.PSChildName
    $Guid = (Get-ItemProperty "HKLM:\SYSTEM\ControlSet001\Services\$SubKeyName").ImagePath
    }
}

$GuidParser1 = $Guid -split "&s="
$GuidParser2 = $GuidParser1[1] -split "&k="
$Guid = $GuidParser2[0]
Set-Asset-Field -Subdomain $subdomain -Name "ScreenConnect GUID" -Value $Guid
