param([string]$CapstoneConfig = ".\config\capstone.json")
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$cfg = Get-Content $CapstoneConfig -Raw | ConvertFrom-Json
$permLabel = $cfg.Capstone.PermanentLabel
$tempLabel = $cfg.Capstone.TemporaryLabel
$tempYears = [int]$cfg.Capstone.TemporaryYears
$capstoneUPNs = @(); $cfg.Capstone.MailboxRoles | ForEach-Object { $capstoneUPNs += $_.UPNs }
if (-not (Get-Label -Identity $permLabel -ErrorAction SilentlyContinue)) {
  New-Label -Name $permLabel -RetentionAction Keep -RetentionDuration Unlimited -ContentType "ExchangeEmail" -IsRecordLabel $true | Out-Null
}
if (-not (Get-Label -Identity $tempLabel -ErrorAction SilentlyContinue)) {
  New-Label -Name $tempLabel -RetentionAction KeepAndDelete -RetentionDuration "$tempYears Years" -ContentType "ExchangeEmail" -IsRecordLabel $false | Out-Null
}
$permPolicyName = "Capstone – Email Permanent"
$tempPolicyName = "Agency Email – 7 Years"
if (-not (Get-RetentionCompliancePolicy -Identity $permPolicyName -ErrorAction SilentlyContinue)) {
  New-RetentionCompliancePolicy -Name $permPolicyName -ExchangeLocation $capstoneUPNs | Out-Null
}
if (-not (Get-RetentionCompliancePolicy -Identity $tempPolicyName -ErrorAction SilentlyContinue)) {
  New-RetentionCompliancePolicy -Name $tempPolicyName -ExchangeLocation All -ExcludedExchangeLocation $capstoneUPNs | Out-Null
}
if (-not (Get-RetentionComplianceRule -Identity "Capstone – Apply Permanent to Capstone Mailboxes" -ErrorAction SilentlyContinue)) {
  New-RetentionComplianceRule -Name "Capstone – Apply Permanent to Capstone Mailboxes" -Policy $permPolicyName -ApplyComplianceTag $permLabel | Out-Null
}
if (-not (Get-RetentionComplianceRule -Identity "Agency Email – Apply 7 Years to Non-Capstone" -ErrorAction SilentlyContinue)) {
  New-RetentionComplianceRule -Name "Agency Email – Apply 7 Years to Non-Capstone" -Policy $tempPolicyName -ApplyComplianceTag $tempLabel | Out-Null
}
