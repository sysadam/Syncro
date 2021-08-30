
# Get profile list from Chromes local state
$statePath = "C:\Users\${env:USERNAME}\AppData\Local\Microsoft\Edge\User Data\Local State"
$state = Get-Content $statePath

# Using Serializer instead of ConvertFrom-Json because https://github.com/PowerShell/PowerShell/issues/1755
[void][System.Reflection.Assembly]::LoadWithPartialName('System.Web.Extensions')
$jsser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$jsser.MaxJsonLength = $jsser.MaxJsonLength * 10

$serProfiles = $jsser.DeserializeObject($state).profile.info_cache

$profiles = @()
$serProfiles.Keys.ForEach{
    $profile = New-Object -TypeName psobject -Property @{
        'Id'   = $_
    }
    $profiles += $profile
}

$profiles | Select-Object -ExpandProperty id

