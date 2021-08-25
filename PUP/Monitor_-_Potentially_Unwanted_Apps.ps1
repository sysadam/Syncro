Import-Module $env:SyncroModule -WarningAction SilentlyContinue

function DownloadFilesFromRepo {
    Param(
        [string]$Owner,
        [string]$Repository,
        [string]$Path
    )
    
    $baseUri = "https://api.github.com/"
    $args = "repos/$Owner/$Repository/contents/$Path"
    $wr = Invoke-WebRequest -Uri $($baseuri + $args)
    $objects = $wr.Content | ConvertFrom-Json
    $files = $objects | where { $_.type -eq "file" } | Select -exp download_url
    $directories = $objects | where { $_.type -eq "dir" }
        
    $directories | ForEach-Object { 
        DownloadFilesFromRepo -Owner $Owner -Repository $Repository -Path $_.path -DestinationPath $($DestinationPath + $_.name)
    }
    
    foreach ($file in $files) {
        try {
            $a = Invoke-WebRequest -Uri $file -ErrorAction Stop
            $a.Content
        }
        catch {
            throw "Unable to download '$($file.path)'"
        }
    }
    
}

# For full functionality:
# Create an 'Allowed Apps' customer custom field and asset custom field in Syncro Admin
# Add Syncro platform script variables for $orgallowlist and $assetallowlist and link them to your custom fields

# Application list arrays, you can add more if you want
Write-Host "Downloading JSON files from GitHub"
$security = DownloadFilesFromRepo -Owner AdamNSTA -Repository Syncro -Path "/PUP/security.json" | ConvertFrom-Json
$remoteaccess = DownloadFilesFromRepo -Owner AdamNSTA -Repository Syncro -Path "/PUP/remoteaccess.json" | ConvertFrom-Json
$rmm = DownloadFilesFromRepo -Owner AdamNSTA -Repository Syncro -Path "/PUP/rmm.json" | ConvertFrom-Json
$crapware = DownloadFilesFromRepo -Owner AdamNSTA -Repository Syncro -Path "/PUP/crapware.json" | ConvertFrom-Json
# TRON 
$oem = DownloadFilesFromRepo -Owner AdamNSTA -Repository Syncro -Path "/PUP/OEM.json" | ConvertFrom-Json

# Combine our lists, if you create more lists be sure to add them here
$apps = $security + $remoteaccess + $rmm + $crapware + $oem

# Allowlist array, you must use the full name for the matching to work!
$allowlist = @"
[
    "ScreenConnect Client (0c34888a41840915)",
    "ScreenConnect Client (60cbdd4413783e37)",
    "Splashtop Software Updater",
    "Splashtop for RMM",
    "Splashtop Streamer",
    "Datto Windows Agent",
    "Webroot SecureAnywhere",
    "Microsoft Search in Bing",
    "Dell PointStick Driver",
    "Dell Command | Update",
    "Dell Touchpad",
    "Dell Power Manager Service"
]
"@ | ConvertFrom-Json
Write-Host -ForegroundColor Yellow "Allowed Apps at Root Level: $allowlist"
$allowlist += ($orgallowlist -split ",").Trim()
Write-Output "Allowed Apps at Organization Level: $orgallowlist"
$allowlist += ($assetallowlist -split ",").Trim()
Write-Output "Allowed Apps at Asset Level: $assetallowlist"

# Grab the registry uninstall keys to search against (x86 and x64)
$software = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\" | Get-ItemProperty
if ([Environment]::Is64BitOperatingSystem) {
    $software += Get-ChildItem "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\" | Get-ItemProperty
}

# Clear the output variable so we don't get confused while testing
$output = ''

# Cycle through each app in the apps array searching for matches and store them
$outputApps = foreach ($app in $apps) {
    $software | Where-Object { $_.DisplayName -match "$app" -and $allowlist -notcontains $_.DisplayName } | Select-Object @{N = "DisplayName"; E = { $_.DisplayName } }, @{N = "UninstallString"; E = { $_.UninstallString } }, @{N = "MatchingApp"; E = { $app } }
}


if ($outputApps) {
    Write-Output "PUP Found:"
    $report = ($outputApps | Select-Object -Unique) | Format-List | Out-String
    Write-Output "Apps: $report"
    #Rmm-Alert -Category 'Potentially Unwanted Applications' -Body "Apps Found: $report"
    exit 1
}
else {
    Write-Host "No Apps Found."
    Close-Rmm-Alert -Category "Potentially Unwanted Applications"
}