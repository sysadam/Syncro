Import-Module $env:SyncroModule -WarningAction SilentlyContinue
$file = 'CitrixWorkspaceApp21.exe'
$link = "https://downloadplugins.citrix.com/ReceiverUpdates/Prod/Receiver/Win/CitrixWorkspaceApp21.7.0.44.exe"
$tmp = "$env:TEMP\$file"
$client = New-Object System.Net.WebClient
$client.DownloadFile($link, $tmp)
Start-Process -filepath "$tmp" -ArgumentList "/silent /uninstall"