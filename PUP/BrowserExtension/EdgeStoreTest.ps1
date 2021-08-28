$url = "https://microsoftedge.microsoft.com/addons/detail/odagciepglpfijopcmfipefombmkkgld/?hl=en-us"
    

# You may need to include proxy information
# $WebRequest = Invoke-WebRequest -Uri $url -ErrorAction Stop -Proxy 'http://proxy:port' -ProxyUseDefaultCredentials
    
$WebRequest = Invoke-WebRequest -Uri $url
$WebRequest
$WebRequest.ParsedHtml.title
    
$ExtTitle = $WebRequest.ParsedHtml.title
if ($ExtTitle -match '\s-\s.*$') {
    $Title = $ExtTitle -replace '\s-\s.*$', ''
    $extType = 'ChromeStore'
    
}

    
# Screen scrape the Description meta-data
$webRequest.AllElements.InnerHTML | Where-Object { $_ -match '<meta name="Description" content="([^"]+)">' } | Select-object -First 1 | ForEach-Object { $Matches[1] }

                      