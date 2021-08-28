# PS script to get FireFox Ext and put in WMI
# Some script code from Ivanti. 
# Original idea I saw was from SKissinger for Chrome Ext for SCCM 2012. 

# Default extensions are ignored since they aren't visible to users. 

# Need to run with admin permissions to manipulate WMI.


function Convert-UTCtoLocal {
param(
[parameter(Mandatory=$true)]
[String] $UTCTime
)

    $strCurrentTimeZone = (Get-WmiObject win32_timezone).StandardName
    $TZ = [System.TimeZoneInfo]::FindSystemTimeZoneById($strCurrentTimeZone)
    $LocalTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($UTCTime, $TZ)
    return $LocalTime
}

$parentdir = "C:\Users\"
$users = Get-ChildItem $parentdir
$ObjCollection = @()

Foreach($user in $users){

#  $targetdir = "C:\Users\glord\AppData\Roaming\Mozilla\Firefox\Profiles\"

  # get profile folder
  $targetdir = ""
  $ffdir = $parentdir + $user.ToString() + "\AppData\Roaming\Mozilla\Firefox\Profiles" 
  $ejsons = if (test-path $ffdir) {Get-ChildItem -path $ffdir -File  -Filter "extensions.json" -Recurse}
  foreach ($ejson in $ejsons) {
    

    # read preferences file in Default folder
    $targetdir = $ejson.directoryname

    # get firefox version - yes it is in the loop. Had to determine profile location.
    $lines = $null 
    if (test-path "$targetdir\compatibility.ini") {$lines=Get-Content "$targetdir\compatibility.ini"}
    foreach ($l in $lines) {
        if ($l -like "lastVersion*"){
            $ls1 = $l.split("=")
            $ls2 = $ls1[1].split("_")
            $ffversion = $ls2[0]
        }
    }



    if (test-path "$targetdir\extensions.json") {
       $prefs = Get-Content "$targetdir\extensions.json"  | ConvertFrom-Json  # Read Prefernces JSON file
       $prefs =  $prefs.addons

        # $prefs = Get-Content "$targetdir\containers.json"  | ConvertFrom-Json
        # $prefs = Get-Content "$targetdir\addons.json"  | ConvertFrom-Json


       Foreach($pref in $prefs){
 
            $obj = New-Object System.Object
            #$pref = $($ext)
            $Permissions = ""  # force permissions variable to string

            # view variable contents for testing
            # $pref 
            # $pref.manifest

            $name = $pref.defaultlocale.name
            $version = $pref.version
            $description = $pref.defaultlocale.description
            $active = $pref.active
            $visible = $pref.visible
            $appdisabled = $pref.appdisabled
            $userdisabled = $pref.userdisabled
            $hidden = $pref.hidden
            $location = $pref.location
            $id = $pref.id
            $sourceURI = $pref.sourceURI

            $Ptemp = $pref.userpermissions.permissions
            foreach ($pt in $Ptemp) {$Permissions = $Permissions + $pt.tostring() + "._."} # convert array to string to store in WMI. Use ._. entry separator.


            # install time conversion
            $p = [double]$pref.installdate
            $p = ($p ) / 1000 #//divide by 1,000 because we are going to add seconds on to the base date
            $date = get-date -date "1970-01-01 00:00:00"
            $date = $date.AddSeconds($p)
            $localtimezn = Convert-UTCtoLocal($date)
            #$localtimezn


            #get name and version from json and add to object
            $obj | Add-Member -MemberType NoteProperty -Name Name -Value $name
            $obj | Add-Member -MemberType NoteProperty -Name Version -Value $version
            $obj | Add-Member -MemberType NoteProperty -Name Description -Value $description
            $obj | Add-Member -MemberType NoteProperty -Name Permissions -Value $Permissions
            $obj | Add-Member -MemberType NoteProperty -Name ID -Value $id
            $obj | Add-Member -MemberType NoteProperty -Name Active -Value $active
            $obj | Add-Member -MemberType NoteProperty -Name visible -Value $visible
            $obj | Add-Member -MemberType NoteProperty -Name appdisabled -Value $appdisabled
            $obj | Add-Member -MemberType NoteProperty -Name userdisabled -Value $userdisabled
            $obj | Add-Member -MemberType NoteProperty -Name hidden -Value $hidden
            $obj | Add-Member -MemberType NoteProperty -Name location -Value $location
            $obj | Add-Member -MemberType NoteProperty -Name sourceURI -Value $sourceURI

            $obj | Add-Member -MemberType NoteProperty -Name DateInstall -Value $localtimezn.ToString()

            $obj | Add-Member -MemberType NoteProperty -Name User -Value $user
            $obj | Add-Member -MemberType NoteProperty -Name FireFoxVer -Value $ffversion
            $obj | Add-Member -MemberType NoteProperty -Name LastScan -Value $(Get-Date)

        
        # ignore default extensions    
        if($location -ne "app-builtin" -and $location -ne "app-system-defaults"){ 
            Write-Output @{Name = $obj.Name; Version = $obj.Version; Description = $obj.Description; Permissions = $obj.Permissions; ID = $obj.ID; DateInstall = $obj.DateInstall; active = $obj.active; visible = $obj.visible; appdisabled = $obj.appdisabled; userdisabled = $obj.userdisabled; hidden = $obj.hidden; location = $obj.location; sourceURI = $obj.sourceURI; User = $obj.User; FireFoxVer = $obj.FireFoxVer; LastScan = $obj.LastScan}         

            # items for testing or debug. Not saved in WMI class
            #$obj


            $ObjCollection += $obj  # used for examining the data later for troubleshooting. 
        }
       } # end foreach extensions
    } # end if pref file found
  } # end foreach json location
} # end foreach users 