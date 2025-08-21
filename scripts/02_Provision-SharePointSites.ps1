param([string]$ConfigPath = ".\config\sharepoint-sites.json")
Install-Module PnP.PowerShell -Force
Import-Module PnP.PowerShell
Import-Module Microsoft.Graph.Identity.DirectoryManagement
$appId = $env:M365_APP_ID
$thumb = $env:M365_APP_CERT_THUMBPRINT
$tenantId = $env:M365_TENANT_ID
if (-not $appId -or -not $thumb -or -not $tenantId) {
  throw "Missing required environment variables M365_APP_ID, M365_APP_CERT_THUMBPRINT, or M365_TENANT_ID"
}
$domain = (Get-MgDomain | Where-Object { $_.IsDefault }).Id
Connect-PnPOnline -Url "https://$domain-admin.sharepoint.com" -ClientId $appId -Thumbprint $thumb -Tenant $tenantId
$sites = Get-Content $ConfigPath | ConvertFrom-Json
foreach ($s in $sites) {
  $url = "https://$domain.sharepoint.com/sites/$($s.Alias)"
  $existing = Get-PnPSite -Identity $url -ErrorAction SilentlyContinue
  if (-not $existing) {
    New-PnPSite -Type CommunicationSite -Title $s.Title -Url $url -Description $s.Description | Out-Null
    Write-Host "Created site $($s.Alias)"
  } else {
    Write-Host "Site $($s.Alias) already exists"
  }
}
