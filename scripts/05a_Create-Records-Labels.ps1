param(
  [string]$FilePlan = ".\config\fileplan.csv",
  [string]$SitesConfig = ".\config\sharepoint-sites.json"
)

$plan = Import-Csv $FilePlan
foreach ($lab in $plan) {
  $params = @{ Name = $lab.LabelName }

  if ($lab.Comment) { $params.Comment = $lab.Comment }
  if ($lab.Notes) { $params.Notes = $lab.Notes }
  if ($lab.IsRecordLabel -ne '') { $params.IsRecordLabel = [System.Convert]::ToBoolean($lab.IsRecordLabel) }
  if ($lab.RetentionAction) { $params.RetentionAction = $lab.RetentionAction }
  if ($lab.RetentionDuration) {
    $dur = $lab.RetentionDuration
    if ($dur -ne 'Unlimited') { $dur = [int]$dur }
    $params.RetentionDuration = $dur
  }
  if ($lab.RetentionType) { $params.RetentionType = $lab.RetentionType }
  if ($lab.ReviewerEmail) {
    $params.ReviewerEmail = $lab.ReviewerEmail.Split(',') | ForEach-Object { $_.Trim() }
  }

  $fp = @()
  foreach ($prop in 'ReferenceId','DepartmentName','Category','SubCategory','AuthorityType','CitationName','CitationUrl','CitationJurisdiction','Regulatory') {
    $val = $lab.$prop
    if ($val) { $fp += @{ Name = $prop; Value = $val } }
  }
  if ($fp.Count) { $params.FilePlanProperty = $fp }

  if ($lab.EventType) {
    $evt = Get-ComplianceRetentionEventType -Identity $lab.EventType -ErrorAction SilentlyContinue
    if (-not $evt) {
      New-ComplianceRetentionEventType -Name $lab.EventType -Comment "$($lab.LabelName) event" | Out-Null
    }
    $params.EventType = $lab.EventType
  }
  if ($lab.IsRecordUnlockedAsDefault -ne '') { $params.IsRecordUnlockedAsDefault = [System.Convert]::ToBoolean($lab.IsRecordUnlockedAsDefault) }
  if ($lab.ComplianceTagForNextStage) { $params.ComplianceTagForNextStage = $lab.ComplianceTagForNextStage }

  $existing = Get-ComplianceTag -Identity $lab.LabelName -ErrorAction SilentlyContinue
  if (-not $existing) {
    New-ComplianceTag @params
  }
}

# publish labels to SharePoint sites
$labelNames = $plan.LabelName
$domain = (Get-MgDomain | Where-Object { $_.IsDefault }).Id
$siteDefs = Get-Content $SitesConfig | ConvertFrom-Json
$sites = $siteDefs | ForEach-Object { "https://$domain.sharepoint.com/sites/$($_.Alias)" }
$policyName = "Records SharePoint Policy"
$policy = Get-RetentionCompliancePolicy -Identity $policyName -ErrorAction SilentlyContinue
if (-not $policy) {
  $policy = New-RetentionCompliancePolicy -Name $policyName -SharePointLocation $sites
} else {
  Set-RetentionCompliancePolicy -Identity $policyName -SharePointLocation $sites
}
foreach ($name in $labelNames) {
  $ruleName = "$name Rule"
  $existingRule = Get-RetentionComplianceRule -Identity $ruleName -ErrorAction SilentlyContinue
  if (-not $existingRule) {
    New-RetentionComplianceRule -Policy $policyName -Name $ruleName -RetentionLabel $name
  }
}
