param(
  [string]$FilePlan = ".\config\fileplan.csv",
  [string]$SitesConfig = ".\config\sharepoint-sites.json"
)

$plan = Import-Csv $FilePlan
foreach ($lab in $plan) {
  $name = $lab.LabelName
  if ($lab.EventType) {
    $evt = Get-ComplianceRetentionEventType -Identity $lab.EventType -ErrorAction SilentlyContinue
    if (-not $evt) {
      New-ComplianceRetentionEventType -Name $lab.EventType -Comment "$name event" | Out-Null
    }
  }
  $existing = Get-ComplianceTag -Identity $name -ErrorAction SilentlyContinue
  if ($existing) { continue }
  $cmdlet = "New-ComplianceTag -Name '$name'"
  if ($lab.Comment) { $cmdlet += " -Comment '" + $lab.Comment + "'" }
  if ($lab.Notes) { $cmdlet += " -Notes '" + $lab.Notes + "'" }
  if ($lab.IsRecordLabel) { $cmdlet += " -IsRecordLabel " + $lab.IsRecordLabel }
  if ($lab.RetentionAction) { $cmdlet += " -RetentionAction " + $lab.RetentionAction }
  if ($lab.RetentionDuration) { $cmdlet += " -RetentionDuration " + $lab.RetentionDuration }
  if ($lab.RetentionType) { $cmdlet += " -RetentionType " + $lab.RetentionType }
  if ($lab.ReviewerEmail) {
    $emails = $lab.ReviewerEmail.Split(",") | ForEach-Object { $_.Trim() }
    if ($emails.Count) {
      $eml = "@(" + (($emails | ForEach-Object { "'$_'" }) -join ",") + ")"
      $cmdlet += " -ReviewerEmail $eml"
    }
  }
  $fp = @()
  foreach ($prop in 'ReferenceId','DepartmentName','Category','SubCategory','AuthorityType','CitationName','CitationUrl','CitationJurisdiction','Regulatory') {
    $val = $lab.$prop
    if ($val) { $fp += "@{Name='$prop';Value='$val'}" }
  }
  if ($fp.Count) { $cmdlet += " -FilePlanProperty @(" + ($fp -join ',') + ")" }
  if ($lab.EventType) { $cmdlet += " -EventType '" + $lab.EventType + "'" }
  if ($lab.IsRecordUnlockedAsDefault) { $cmdlet += " -IsRecordUnlockedAsDefault " + $lab.IsRecordUnlockedAsDefault }
  if ($lab.ComplianceTagForNextStage) { $cmdlet += " -ComplianceTagForNextStage '" + $lab.ComplianceTagForNextStage + "'" }
  Invoke-Expression $cmdlet
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
