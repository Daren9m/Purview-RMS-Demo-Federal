param([string]$CapstoneConfig = ".\config\capstone.json")

if (-not (Get-Module ExchangeOnlineManagement -ListAvailable)) {
  throw "ExchangeOnlineManagement module is required."
}
if (-not (Get-Command Connect-IPPSSession -ErrorAction SilentlyContinue)) {
  Import-Module ExchangeOnlineManagement -ErrorAction Stop
}

$cfg = Get-Content $CapstoneConfig -Raw | ConvertFrom-Json
$permLabel   = $cfg.Capstone.PermanentLabel
$tempLabel   = $cfg.Capstone.TemporaryLabel
$tempYears   = [int]$cfg.Capstone.TemporaryYears
$capstoneUPNs = @()
$cfg.Capstone.MailboxRoles | ForEach-Object { $capstoneUPNs += $_.UPNs }

# Ensure labels
$existing = Get-Label -Identity $permLabel -ErrorAction SilentlyContinue
if (-not $existing) {
  New-Label -Name $permLabel -RetentionAction Keep -RetentionDuration Unlimited -ContentType "ExchangeEmail" -IsRecordLabel $true | Out-Null
}
$existing = Get-Label -Identity $tempLabel -ErrorAction SilentlyContinue
if (-not $existing) {
  New-Label -Name $tempLabel -RetentionAction KeepAndDelete -RetentionDuration "$tempYears Years" -ContentType "ExchangeEmail" -IsRecordLabel $false | Out-Null
}

# Policies
$permPolicyName = "Capstone – Email Permanent"
$tempPolicyName = "Agency Email – 7 Years"

$permPolicy = Get-RetentionCompliancePolicy -Identity $permPolicyName -ErrorAction SilentlyContinue
if (-not $permPolicy) {
  $permPolicy = New-RetentionCompliancePolicy -Name $permPolicyName -ExchangeLocation $capstoneUPNs
}

$tempPolicy = Get-RetentionCompliancePolicy -Identity $tempPolicyName -ErrorAction SilentlyContinue
if (-not $tempPolicy) {
  $tempPolicy = New-RetentionCompliancePolicy -Name $tempPolicyName -ExchangeLocation All -ExcludedExchangeLocation $capstoneUPNs
}

# Rules
$permRuleName = "Capstone – Apply Permanent to Capstone Mailboxes"
$tempRuleName = "Agency Email – Apply 7 Years to Non-Capstone"

if (-not (Get-RetentionComplianceRule -Identity $permRuleName -ErrorAction SilentlyContinue)) {
  New-RetentionComplianceRule -Name $permRuleName -Policy $permPolicyName -ApplyComplianceTag $permLabel | Out-Null
}
if (-not (Get-RetentionComplianceRule -Identity $tempRuleName -ErrorAction SilentlyContinue)) {
  New-RetentionComplianceRule -Name $tempRuleName -Policy $tempPolicyName -ApplyComplianceTag $tempLabel | Out-Null
}

Write-Host "Capstone email configuration complete."
