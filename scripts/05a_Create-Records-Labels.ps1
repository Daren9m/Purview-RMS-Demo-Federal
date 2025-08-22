param([string]$FilePlan = ".\config\fileplan.json")
$plan = Get-Content $FilePlan -Raw | ConvertFrom-Json
$plan = $plan[1]
foreach ($item in $plan) {
  if ($item.EventType) {
    $evt = Get-ComplianceRetentionEventType -Identity $item.EventType -ErrorAction SilentlyContinue
    if (-not $evt) {
      New-ComplianceRetentionEventType -Name $item.EventType -Comment "$($item.Name) event" | Out-Null
    }
  }
  $existing = Get-ComplianceTag -Identity $item.Name -ErrorAction SilentlyContinue
  if ($existing) { continue }
  $params = @{
    Name = $item.Name
    RetentionAction = $item.RetentionAction
    RetentionDuration = $item.RetentionDuration
    RetentionType = $item.RetentionType
      }
  if ($item.FilePlanProperty) { $params.FilePlanProperty = $item.FilePlanProperty }
  if ($item.IsRecordLabel) { $params.IsRecordLabel = $item.IsRecordLabel }
  if ($item.EventType) { $params.EventType = $item.EventType }
  New-ComplianceTag @params
}
