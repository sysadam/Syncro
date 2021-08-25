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
$security = DownloadFilesFromRepo -Owner AdamNSTA -Repository Syncro -Path "/PUP/security.json" | ConvertFrom-Json
$security

$remoteaccess = @"
[
    "aeroadmin",
    "alpemix",
    "ammyy",
    "anydesk",
    "asg-remote",
    "aspia",
    "bomgar",
    "\bchrome remote",
    "\bcloudberry remote",
    "dameware",
    "dayon",
    "deskroll",
    "dualmon",
    "dwservice",
    "ehorus",
    "fixme.it",
    "gosupportnow",
    "gotoassist",
    "gotomypc",
    "guacamole",
    "impcremote",
    "instant housecall",
    "instatech",
    "isl alwayson",
    "isl light",
    "join.me",
    "jump desktop",
    "kaseya",
    "lite manager",
    "logmein",
    "mikogo",
    "meshcentral",
    "mremoteng",
    "nomachine",
    "opennx",
    "optitune",
    "pilixo",
    "\bradmin",
    "remotetopc",
    "\bremotepc",
    "\bremote utilities",
    "rescueassist",
    "screenconnect",
    "showmypc",
    "simplehelp",
    "splashtop",
    "supremo",
    "take control",
    "teamviewer",
    "thinfinity",
    "ultraviewer",
    "vnc",
    "wayk now",
    "x2go",
    "zoho assist"
]
"@ | ConvertFrom-Json
$rmm = @"
[
    "kaseya",
    "datto",
    "solarwinds",
    "ninja",
    "GFI",
    "atera",
    "continuum",
    "ITSupport247",
    "ITSPlatform"
]
"@ | ConvertFrom-Json

$crapware = @"
[ 
    "CCleaner"
]
"@ | ConvertFrom-Json
# TRON 
$oem = @"
[
    "555",
    "AdBlocknWatch",
    "AppToU",
    "CCCHelp",
    "ClipGenie",
    "CoolWWW",
    "Coupon",
    "Cydoor",
    "Esuack",
    "FashionLife",
    "Freenpro25",
    "Gamevance",
    "MapsGalaxy",
    "QuickTime",
    "SaferSurf",
    "SaveForYou",
    "Savings",
    "Search",
    "Shop_and_Up",
    "Shopper",
    "SpeedUpMyPC",
    "TidyNetwork",
    "Toolbar",
    "Trial",
    "Virtumundo",
    "VirusProtectPro",
    "WeatherBug",
    "WhenUsave",
    "Zango",
    "iBryte",
    "iStart123",
    "180Solution",
    "24x7Help",
    "3vix",
    "AVGTuneUp",
    "Acer",
    "AdobeShockwave",
    "Advanced Registry",
    "AdvancedFX Engine",
    "Akamai",
    "Altnet",
    "Amazon Browser",
    "Any Video Converter",
    "AppsHat",
    "ArcadeParlor",
    "AtuZi",
    "Baidu PC Faster",
    "Big Fish",
    "Bing",
    "BlueStack",
    "Bonzi Buddy",
    "BrowserOptimize",
    "BrowserSafeguard",
    "Buzzdock",
    "CWA Reminder by We-Care.com",
    "ClickForSale",
    "CloudScout",
    "DealPly",
    "DealScout for Internet Explorer",
    "Dell",
    "Discovery Tools",
    "Download Updater",
    "DriverUpdate",
    "Face Theme",
    "File Type Assistant",
    "Files Opened",
    "FilesFrog Update Checker",
    "Free Download Manager",
    "Free Studio",
    "Free YouTube",
    "GetSavin",
    "HD-Total-",
    "HPAssistant",
    "HPDocumentation",
    "HPGuide",
    "HPHelp",
    "HPNotifications",
    "HPRegistration",
    "HPStudy",
    "HPSupport",
    "HPUpdate",
    "IBUpdater",
    "IObit",
    "IWon",
    "Iminent",
    "InfoAtoms",
    "InstaCodecs",
    "IntelMEUninstallLegacy",
    "IntelManagement",
    "IntelSmart",
    "Launch Manager",
    "Lenovo",
    "LinkSwift",
    "Live Updater",
    "Live! Cam Avatar",
    "MPlayerplus",
    "MapsGalaxy",
    "McAfee Security Scan",
    "Media Buzz",
    "Media Gallery",
    "Media View",
    "Media Watch",
    "Mindspark",
    "MobileWiFi",
    "Mobogenie",
    "Move Media",
    "My HP",
    "My Web Searc",
    "MyPC Backup",
    "Nero",
    "Norton Internet",
    "OMG Music Plus",
    "OOBE",
    "Optimizer",
    "Orbit Downloader",
    "PMB",
    "Pdf995",
    "Plus-HD-1.3",
    "Price Check by AOL",
    "PrivDog",
    "ProductivityToolbar for IE",
    "QuickShare",
    "Qwiklinx",
    "RadioRage",
    "Raptr",
    "RealDownloader",
    "RealNetworks",
    "RealUpgrade",
    "RegClean Pro",
    "RegInOut",
    "Remote Keyboard",
    "Remote Play with Playstation",
    "Rich Media View",
    "Rock Turner",
    "Roxio",
    "SLOW-PCfighter",
    "SaveOn",
    "ScorpionSave",
    "SelectionLinks",
    "Shop To Win",
    "ShopAtHome",
    "Shopper",
    "Shopping",
    "SimilarDeals",
    "SmartWebPrinting",
    "Smiley Central",
    "SocialSafe",
    "Software Assist",
    "Software Updater",
    "Soluto",
    "Sonic CinePlayer",
    "Sony Music",
    "SpeedUpMyPc",
    "Speedial",
    "Super Optimizer",
    "SweetIM for Messenger",
    "SweetPacks",
    "SySaver",
    "The Gator",
    "TidyNetwork.com",
    "Toolbar",
    "TopArcadeHits",
    "Toshiba",
    "Uninstall Helper",
    "UserGuide",
    "VAIO",
    "VGClient",
    "Video Converter",
    "Video Player",
    "VideoDownloadConverter",
    "VideoFileDownload",
    "VisualBee",
    "Wajam",
    "WebConnect",
    "Webshots",
    "WhenU",
    "WildGames",
    "WildTangent",
    "Windows Internet Guard",
    "WiseConvert",
    "YahooBrowser",
    "YahooSoftware",
    "YahooToolbar",
    "Yammer",
    "Yontoo",
    "YouTube Downloader",
    "ZD Manager",
    "Zip Opener Packages",
    "eBay",
    "eMachines",
    "flash-Enhancer",
    "hpStatusAlerts",
    "lucky leap"
]
"@ | ConvertFrom-Json

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
    Rmm-Alert -Category 'Potentially Unwanted Applications' -Body "Apps Found: $report"
    exit 1
}
else {
    Write-Host "No Apps Found."
    Close-Rmm-Alert -Category "Potentially Unwanted Applications"
}