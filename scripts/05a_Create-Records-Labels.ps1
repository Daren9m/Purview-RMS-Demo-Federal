param([string]$FilePlan = ".\config\fileplan.json")
$plan = Get-Content $FilePlan -Raw | ConvertFrom-Json
foreach ($item in $plan) {
  if ($item.EventType) {
    $evt = Get-RetentionEventType -Identity $item.EventType -ErrorAction SilentlyContinue
    if (-not $evt) {
      New-RetentionEventType -Name $item.EventType -Description "$($item.Name) event" | Out-Null
    }
  }
  $existing = Get-ComplianceTag -Identity $item.Name -ErrorAction SilentlyContinue
  if ($existing) { continue }
  $params = @{
    Name = $item.Name
    RetentionAction = $item.RetentionAction
    RetentionDuration = $item.RetentionDuration
    RetentionType = $item.RetentionType
    ContentType = $item.ContentType
  }
  if ($item.FilePlanProperty) { $params.FilePlanProperty = $item.FilePlanProperty }
  if ($item.EventType) { $params.EventType = $item.EventType }
  New-ComplianceTag @params
  if ($item.IsRecordLabel -or $item.AutoDelete) {
    $setParams = @{ Identity = $item.Name }
    if ($item.IsRecordLabel) { $setParams.IsRecordLabel = $true }
    if ($item.AutoDelete) { $setParams.AutoDelete = $true }
    Set-ComplianceTag @setParams
  }
}
