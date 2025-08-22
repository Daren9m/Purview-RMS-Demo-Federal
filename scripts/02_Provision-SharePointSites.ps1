param(
  [string]$ConfigPath = ".\config\sharepoint-sites.json"
)

if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
  Install-Module PnP.PowerShell -Force
}
Import-Module PnP.PowerShell -ErrorAction Stop

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Identity.DirectoryManagement)) {
  Install-Module Microsoft.Graph.Identity.DirectoryManagement -Force
}
Import-Module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction Stop

if (-not (Get-MgContext)) {
  Connect-MgGraph -Scopes "Domain.Read.All" -UseDeviceCode -NoWelcome
}

$domain = (Get-MgDomain | Where-Object { $_.IsDefault }).Id
Connect-PnPOnline -Url "https://$domain-admin.sharepoint.com" -Interactive

$sites = Get-Content $ConfigPath | ConvertFrom-Json
foreach ($s in $sites) {
  $url = "https://$domain.sharepoint.com/sites/$($s.Alias)"
  try {
    $existing = Get-PnPSite -Identity $url -ErrorAction Stop
  } catch {
    $existing = $null
  }
  if (-not $existing) {
    try {
      New-PnPSite -Type CommunicationSite -Title $s.Title -Url $url -Description $s.Description | Out-Null
      Write-Host "Created site $($s.Alias)"
    } catch {
      Write-Warning "Failed to create site $($s.Alias): $_"
    }
  } else {
    Write-Host "Site $($s.Alias) already exists"
  }
}
