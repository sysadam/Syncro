Import-Module $env:SyncroModule -WarningAction SilentlyContinue

# For full functionality:
# Create an 'Allowed Apps' customer custom field and asset custom field in Syncro Admin
# Add Syncro platform script variables for $orgallowlist and $assetallowlist and link them to your custom fields

# Application list arrays, you can add more if you want
$security = @("ahnlab", "avast", "avg", "avira", "bitdefender", "checkpoint", "clamwin", "comodo", "dr.web", "eset ", "fortinet", "f-prot", "f-secure", "g data", "immunet", "kaspersky", "mcafee", "nano", "norton", "panda", "qihoo 360", "segurazo", "sophos", "symantec", "trend micro", "trustport", "webroot", "zonealarm")
$remoteaccess = @("aeroadmin", "alpemix", "ammyy", "anydesk", "asg-remote", "aspia", "bomgar", "chrome remote", "cloudberry remote", "dameware", "dayon", "deskroll", "dualmon", "dwservice", "ehorus", "fixme.it", "gosupportnow", "gotoassist", "gotomypc", "guacamole", "impcremote", "instant housecall", "instatech", "isl alwayson", "isl light", "join.me", "jump desktop", "kaseya", "lite manager", "logmein", "mikogo", "meshcentral", "mremoteng", "nomachine", "opennx", "optitune", "pilixo", "radmin", "remotetopc", "remotepc", "remote utilities", "rescueassist", "screenconnect", "showmypc", "simplehelp", "splashtop", "supremo", "take control", "teamviewer", "thinfinity", "ultraviewer", "vnc", "wayk now", "x2go", "zoho assist")
$rmm = @("kaseya", "datto", "solarwinds", "ninja", "GFI", "atera", "connectwise", "continuum", "ITSupport247","ITSPlatform")

# Combine our lists, if you create more lists be sure to add them here
$apps = $security + $remoteaccess + $rmm

# Allowlist array, you must use the full name for the matching to work!
$allowlist = @("ScreenConnect Client (0c34888a41840915)","ScreenConnect Client (60cbdd4413783e37)","Splashtop Software Updater","Splashtop for RMM","Splashtop Streamer","Datto Windows Agent","Webroot SecureAnywhere")
Write-Output "Allowed Apps at Root Level:" ($allowlist -join ", ")
$allowlist += ($orgallowlist -split ",").Trim()
Write-Output "Allowed Apps at Organization Level: $orgallowlist"
$allowlist += ($assetallowlist -split ",").Trim()
Write-Output "Allowed Apps at Asset Level: $assetallowlist"

# Grab the registry uninstall keys to search against (x86 and x64)
$software = Get-ChildItem "HKLM:\LTC\Microsoft\Windows\CurrentVersion\Uninstall\" | Get-ItemProperty
if ([Environment]::Is64BitOperatingSystem) {
    $software += Get-ChildItem "HKLM:\LTC\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\" | Get-ItemProperty
}

# Clear the output variable so we don't get confused while testing
$output = ''

# Cycle through each app in the apps array searching for matches and store them
$output = foreach ($app in $apps) {
    @($software | Where-Object { $_.DisplayName -match "$app" -and $allowlist -notcontains $_.DisplayName } | Select-Object -ExpandProperty DisplayName)
}

# If we found something, report it
if ($output) {
    Write-Output "Apps Found:"
    $report = ($output | Select-Object -Unique) -join  ","
    Write-Output "Products Found: $report"
    #Rmm-Alert -Category 'Potentially Unwanted Applications' -Body "Apps Found: $report"
    exit 1
}
else {
    Write-Host "No Apps Found."
    Close-Rmm-Alert -Category "Potentially Unwanted Applications"
}