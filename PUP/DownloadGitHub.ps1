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
    Get-GitHubFiles -Owner AdamNSTA -Repository Syncro -Path "/PUP/security.json" -DestinationPath "$env:Temp\PUP\"
    Get-GitHubFiles -Owner AdamNSTA -Repository Syncro -Path "/PUP/remoteaccess.json" -DestinationPath "$env:Temp\PUP\"
    Get-GitHubFiles -Owner AdamNSTA -Repository Syncro -Path "/PUP/rmm.json" -DestinationPath "$env:Temp\PUP\"
    Get-GitHubFiles -Owner AdamNSTA -Repository Syncro -Path "/PUP/crapware.json" -DestinationPath "$env:Temp\PUP\"
    Get-GitHubFiles -Owner AdamNSTA -Repository Syncro -Path "/PUP/oem.json" -DestinationPath "$env:Temp\PUP\"
}

try {
    $json = Get-ChildItem -Path "$env:Temp\PUP\" -Filter "*.json"
    $limit = (Get-Date).AddDays(0)
    $over24 = (Get-ChildItem -Path $path | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit })
    if ($NULL -eq $json) {
        Save-GitHubFiles
    }
    elseif ((test-path $json) -and ($True -eq $over24)) {
        #$json | Foreach-Object { Remove-Item $_.FullName -Force }
        Save-GitHubFiles
        Write-Host "Files cached over 24 hours, redownloading"
    }
    else {
        Write-Host "Files cached"
    }
}
catch {
    $_
}


Get-ChildItem -Path "$env:Temp\PUP\" -Filter "*.json" | ForEach-Object {
    New-Variable -Name $_.BaseName -Value $(get-content $_.FullName | ConvertFrom-Json)
}
# Combine our lists, if you create more lists be sure to add them here
$apps = $security + $remoteaccess + $rmm + $crapware + $oem
