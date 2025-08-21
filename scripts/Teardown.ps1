param([switch]$RemoveLabels=$false)
Import-Module Microsoft.Graph.Teams
Import-Module Microsoft.Graph.Sites

$rules = @(
  "Contracts Keywords","FOIA Keywords",
  "Capstone – Apply Permanent to Capstone Mailboxes",
  "Agency Email – Apply 7 Years to Non-Capstone"
)
foreach ($r in $rules) { try { Remove-RetentionComplianceRule -Identity $r -Confirm:$false } catch {} }
$policies = @(
  "AutoApply – Contracts","AutoApply – FOIA",
  "Capstone – Email Permanent","Agency Email – 7 Years"
)
foreach ($p in $policies) { try { Remove-RetentionCompliancePolicy -Identity $p -Confirm:$false } catch {} }
if ($RemoveLabels) {
  $labels = @(
    "Capstone Email – Permanent","Agency Email – 7 Years",
    "FOIA Disclosure Logs – Permanent","FOIA Requests – 6 Years",
    "Contracts – 6 Years","Program Planning – 3 Years","Transitory Records – 90 Days"
  )
  foreach ($l in $labels) { try { Remove-Label -Identity $l -Confirm:$false } catch {} }
}

# Remove demo team if present
$teamName = "Records Demo Team"
$team = Get-MgTeam -All | Where-Object { $_.DisplayName -eq $teamName } | Select-Object -First 1
if ($team) { try { Remove-MgGroup -GroupId $team.Id -Confirm:$false } catch {} }

# Remove demo SharePoint sites
$sitesCfg = ".\config\sharepoint-sites.json"
if (Test-Path $sitesCfg) {
  $sites = Get-Content $sitesCfg | ConvertFrom-Json
  foreach ($s in $sites) {
    $site = Get-MgSite -Search $s.Alias | Where-Object { $_.WebUrl -match "/sites/$($s.Alias)$" } | Select-Object -First 1
    if ($site) { try { Remove-MgSite -SiteId $site.Id -Confirm:$false } catch {} }
  }
}

# Remove retention events and types
$events = "ACQ-24-019 Closeout","FOIA-2023-017 Closed"
foreach ($e in $events) { try { Remove-RetentionEvent -Identity $e -Confirm:$false } catch {} }
$eventTypes = "ContractClose","FOIACaseClosed"
foreach ($et in $eventTypes) { try { Remove-RetentionEventType -Identity $et -Confirm:$false } catch {} }

Write-Host "Teardown complete."
