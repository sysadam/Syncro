$DellClientID = ""
$DellClientSecret = ""
$SyncroSubdomain = ""
$SyncroAPIKey = ""
function get-DellWarranty([Parameter(Mandatory = $true)]$SourceDevice) {
    $today = Get-Date -Format yyyy-MM-dd
    $AuthURI = "https://apigtwb2c.us.dell.com/auth/oauth/v2/token"
    if ($Global:TokenAge -lt (get-date).AddMinutes(-55)) { $global:Token = $null }
    If ($null -eq $global:Token) {
        $OAuth = "$global:DellClientID`:$global:DellClientSecret"
        $Bytes = [System.Text.Encoding]::ASCII.GetBytes($OAuth)
        $EncodedOAuth = [Convert]::ToBase64String($Bytes)
        $headersAuth = @{ "authorization" = "Basic $EncodedOAuth" }
        $Authbody = 'grant_type=client_credentials'
        $AuthResult = Invoke-RESTMethod -Method Post -Uri $AuthURI -Body $AuthBody -Headers $HeadersAuth
        $global:token = $AuthResult.access_token
        $Global:TokenAge = (get-date)
    }
     
    $headersReq = @{ "Authorization" = "Bearer $global:Token" }
    $ReqBody = @{ servicetags = $SourceDevice }
    $WarReq = Invoke-RestMethod -Uri "https://apigtwb2c.us.dell.com/PROD/sbil/eapi/v5/asset-entitlements" -Headers $headersReq -Body $ReqBody -Method Get -ContentType "application/json"
    $warlatest = $warreq.entitlements.enddate | sort-object | select-object -last 1 
    $WarrantyState = if ($warlatest -le $today) { "Expired" } else { "OK" }
    if ($warreq.entitlements.serviceleveldescription) {
        $WarObj = [PSCustomObject]@{
            'Warranty Product name' = $warreq.entitlements.serviceleveldescription -join "`n"
            'StartDate'             = (($warreq.entitlements.startdate | sort-object -Descending | select-object -last 1) -split 'T')[0]
            'EndDate'               = (($warreq.entitlements.enddate | sort-object | select-object -last 1) -split 'T')[0]
            'Warranty Status'       = $WarrantyState
        }
    }
    else {
        $WarObj = [PSCustomObject]@{
            'Warranty Product name' = 'Could not get warranty information'
            'StartDate'             = $null
            'EndDate'               = $null
            'Warranty Status'       = 'Could not get warranty information'
        }
    }
    return $WarObj
}
function GetAll-Customers () {

    <#
    .SYNOPSIS
    This function is used to get all customer records in Syncro. 
    .DESCRIPTION
    The function connects to your Syncro environment and finds all customers
    .EXAMPLE
    GetAll-Customers -SyncroSubDomain $SyncroSubDomain -SyncroAPIKey $SyncroAPIkey
    Retrieves all customers
    .NOTES
    NAME: GetAll-Customers
    #>
    
    [cmdletbinding()]
    
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$SyncroSubdomain,
        [string]$SyncroAPIKey,
        [string]$page
    )
    
    
    $url = "https://$($SyncroSubdomain).syncromsp.com/api/v1/customers?api_key=$($SyncroAPIKey)&page=$($page)"
    $response = Invoke-RestMethod -Uri $url -Method Get -ContentType 'application/json'
    $response
    
}

function Get-SyncroAssets () {
 
    [cmdletbinding()]
    
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$SyncroSubdomain,
        [string]$SyncroAPIKey,
        [string]$page
    )
    
    
    $uri = "https://$SyncroSubdomain.syncromsp.com/api/v1/customer_assets?api_key=$SyncroAPIKey&customer_id=$customer_id"
    $response = Invoke-RestMethod -Uri $uri
    $response = $response.ToString().Replace("AV", "_AV") | ConvertFrom-Json
    $response
    
}

###Fnd All Syncro Customers##########
Write-Host "Getting All Customers In Syncro"

$SyncroCustomers = Do {
    (GetAll-Customers -SyncroSubdomain $SyncroSubdomain -SyncroAPIKey $SyncroAPIKey -page $page).customers
    $page = $page + 1
}Until ($page -gt $totalPageCount)
Write-Host "Found $($SyncroCustomers.Count) Customers in Syncro" -ForegroundColor Green




foreach ($customer in $SyncroCustomers) {
    $customer_id = $customer.id
    $customername = $customer.business_and_full_name

    #connect to syncro and pull all assets for the customer by ID

    Write-Host "Getting All assets for $customername In Syncro"

    $page = 1
    $totalPageCount = (Get-SyncroAssets -SyncroSubdomain $SyncroSubdomain -SyncroAPIKey $SyncroAPIKey -page 1).meta.total_pages
    $SyncroAssets = Do {
        (Get-SyncroAssets -SyncroSubdomain $SyncroSubdomain -SyncroAPIKey $SyncroAPIKey -page $page).assets
        $page = $page + 1
    }Until ($page -gt $totalPageCount)
    Write-Host "Found $($SyncroAssets.Count) assets in Syncro" -ForegroundColor Green

    foreach ($d in $data.assets) {
        if ($d.properties.kabuto_information.general.manufacturer -like "*dell*") {
            Write-Host "Found Dell Computer" -ForegroundColor Green
            $servicetag = $d.properties.kabuto_information.general.serial_number
            $id = $d.id
            Write-Host "Computer has serial $servicetag and has Syncro ID $id"
            $warranty = get-DellWarranty -SourceDevice $servicetag
            $post = @{
                "properties" = 
                @{
                    "Warranty Product Name" = "$($warranty.'Warranty Product name' | Out-string)"
                    "Warranty Start"        = "$($warranty.StartDate | Out-String)"
                    "Warranty End"          = "$($warranty.EndDate |Out-String)"
                    "Warranty Status"       = "$($warranty.'Warranty Status' | Out-String)"
                }
            } | ConvertTo-Json

            $url = "https://$SyncroSubdomain.syncromsp.com/api/v1/customer_assets/$($id)?api_key=$SyncroAPIKey"
            Invoke-WebRequest -uri $url -Method PUT -Body $post -ContentType 'application/json'        
        }
    }
}
