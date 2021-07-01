$WorkspaceID = "KEY"
$WorkspaceKEY = "KEY"
Start-Process "C:\ProgramData\Syncro\bin\MMASetup-AMD64.exe" -ArgumentList "/Q /T:C:\ProgramData\PMP /C" -wait
Start-Process "C:\ProgramData\PMP\Setup.exe" -ArgumentList "/qn NOAPM=0 ADD_OPINSIGHTS_WORKSPACE=1 OPINSIGHTS_WORKSPACE_AZURE_CLOUD_TYPE=0 OPINSIGHTS_WORKSPACE_ID=$WorkspaceID OPINSIGHTS_WORKSPACE_KEY=$WorkspaceKEY AcceptEndUserLicenseAgreement=1" -wait
Remove-Item "C:\ProgramData\PMP" -recurse -force
