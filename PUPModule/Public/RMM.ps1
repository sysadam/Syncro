Function Get-RMM {
    <#
        .EXTERNALHELP Evergreen-help.xml
    #>
    [OutputType([System.Management.Automation.PSObject])]
    param (

    )

    Begin {

        #region Get the per-application manifests from the Evergreen/Manifests folder
        try {
            $params = @{
                Path        = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath "Manifests"
                Filter      = "RMM.json"
                ErrorAction = "Continue"
            }
            Write-Verbose -Message "$($MyInvocation.MyCommand): Search path for application manifests: $($params.Path)."
            $Manifests = Get-ChildItem @params
        }
        catch {
            Throw $_
        }
        #endregion
    }

    Process {
        
        try {
            #region Output details from the manifest/s
            If ($Manifests.Count -gt 0) {
                ForEach ($manifest in $Manifests) {
                    try {
                        # Read the JSON manifest and convert to an object
                        $Json = Get-Content -Path $manifest.FullName | ConvertFrom-Json
                    }
                    catch {
                        Throw $_
                    }

                    If ($Null -ne $Json) {
                        # Build an object from the manifest details and file name and output to the pipeline
                        $PSObject = [PSCustomObject] @{
                            Name      = [System.IO.Path]::GetFileNameWithoutExtension($manifest.Name)
                            App       = $Json.App
                            Publisher = $Json.Publisher
                        }
                        Write-Output -InputObject $PSObject
                    }
                }
            }
            Else {
                Write-Warning -Message "Omit the -Name parameter to return the full list of supported applications."
                Write-Warning -Message "Documentation on how to contribute a new application to the Evergreen project can be found at: $($script:resourceStrings.Uri.Docs)."
                Throw "Failed to return application manifests."
            }

            # Grab the registry uninstall keys to search against (x86 and x64)
            $software = Get-ChildItem "HKLM:\LTC\Microsoft\Windows\CurrentVersion\Uninstall\" | Get-ItemProperty
            if ([Environment]::Is64BitOperatingSystem) {
                $software += Get-ChildItem "HKLM:\LTC\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\" | Get-ItemProperty
            }
            
            # Clear the output variable so we don't get confused while testing
            $output = ''

            # Cycle through each app in the apps array searching for matches and store them
            $outputApps = foreach ($app in $PSObject.App) {
                @($software | Where-Object { $_.DisplayName -match "$app" } | Select-Object -ExpandProperty DisplayName)
                #-and $allowlist -notcontains $_.DisplayName 
            }
            $outputPub = foreach ($app in $PSObject.Publisher) {
                @($software | Where-Object { $_.DisplayName -match "$app" } | Select-Object -ExpandProperty Publisher)
                #-and $allowlist -notcontains $_.DisplayName 
            }

            if ($outputApps -or $outputPub) {
                Write-Output "PUP Found:"
                $reportApps = ($outputApps | Select-Object -Unique) -join ","
                $reportPub = ($outputPub | Select-Object -Unique) -join ","
                if ($outputApps) {
                    Write-Output "Apps: $reportApps"
                }
                if($outputPub) {
                    Write-Output "Publishers: $reportPub"
                }
                #Rmm-Alert -Category 'Potentially Unwanted Applications' -Body "Apps Found: $report"
                #exit 1
            }
            else {
                Write-Host "No Apps Found."
                #Close-Rmm-Alert -Category "Potentially Unwanted Applications"
            }
            #endregion
        }
        catch {
            Throw "$_"
        }

    }

    End {
        # Remove these variables for next run
        Remove-Variable -Name "Output", "Function" -ErrorAction "SilentlyContinue"
    }
}