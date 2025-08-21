param([string]$ConfigPath = ".\config\sharepoint-sites.json")
Install-Module PnP.PowerShell -Force
Import-Module PnP.PowerShell
Import-Module Microsoft.Graph.Identity.DirectoryManagement
$domain = (Get-MgDomain | Where-Object { $_.IsDefault }).Id
Connect-PnPOnline -Url "https://$domain-admin.sharepoint.com" -Interactive
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
