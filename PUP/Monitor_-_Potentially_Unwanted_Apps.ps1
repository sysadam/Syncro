#Import-Module $env:SyncroModule -WarningAction SilentlyContinue

function Get-GitHubFiles {
    Param(
        [string]$Owner,
        [string]$Repository,
        [string]$Path,
        [string]$DestinationPath
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
    
        
    if (-not (Test-Path $DestinationPath)) {
        # Destination path does not exist, let's create it
        try {
            New-Item -Path $DestinationPath -ItemType Directory -ErrorAction Stop
        }
        catch {
            throw "Could not create path '$DestinationPath'!"
        }
    }
    
    foreach ($file in $files) {
        $fileDestination = Join-Path $DestinationPath (Split-Path $file -Leaf)
        try {
            Invoke-WebRequest -Uri $file -OutFile $fileDestination -ErrorAction Stop
            "Grabbed '$($file)' to '$fileDestination'"
        }
        catch {
            throw "Unable to download '$($file.path)'"
        }
    }
    
}

function Save-GitHubFiles {
    Get-GitHubFiles -Owner AdamNSTA -Repository Syncro -Path "/PUP/JSON/" -DestinationPath "$env:Temp\PUP\"
    #Get-ChildItem -Path "C:\GitRepos\Syncro\PUP" -Filter "*.json" | Copy-Item -Destination "$env:localAppData\Temp\PUP" -Verbose -Force
}


$tempPath = "$env:Temp\PUP\"
$tempFiles = Get-ChildItem -Path "$tempPath" -Filter "*.json" -ea SilentlyContinue
$limit = (Get-Date).AddDays(-2)
$over24 = Get-ChildItem -Path "$tempPath" -Filter "*.json" -ErrorAction SilentlyContinue| Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit }
if ($NULL -eq $tempFiles) {
    Write-Host "Caching files"
    Save-GitHubFiles
}
elseif ($over24.Count -ne '0') {
    $tempFiles |%{Remove-Item $_.FullName -Verbose -Force -Confirm:$false -ErrorAction Stop }
    Write-Host "Files cached over 24 hours, redownloading"
    Save-GitHubFiles
}
else {
    Write-Host "Files already cached"
}

#grab lists from temporary files and declare variables.
$tempFiles | ForEach-Object {
    New-Variable -Name $_.BaseName -Value $(get-content $_.FullName | ConvertFrom-Json) -Force
}

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
$software = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\" -ErrorAction SilentlyContinue| Get-ItemProperty
if ([Environment]::Is64BitOperatingSystem) {
    $software += Get-ChildItem "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\" -ErrorAction SilentlyContinue| Get-ItemProperty
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
    #Close-Rmm-Alert -Category "Potentially Unwanted Applications"
}