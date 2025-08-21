# Contract keywords
$policyName = "AutoApply – Contracts"
$ruleName   = "Contracts Keywords"
$labelName  = "Contracts – 6 Years"
if (-not (Get-RetentionCompliancePolicy -Identity $policyName -ErrorAction SilentlyContinue)) {
  New-RetentionCompliancePolicy -Name $policyName -SharePointLocation All -OneDriveLocation All -ExchangeLocation All -TeamsChannelLocation All | Out-Null
}
if (-not (Get-RetentionComplianceRule -Identity $ruleName -ErrorAction SilentlyContinue)) {
  New-RetentionComplianceRule -Name $ruleName -Policy $policyName -ContentContainsSensitiveInformation @(
    @{ Name="Keywords"; operands=@("RFP","Acquisition","Solicitation","Award","Closeout","SOW") }
  ) -ApplyComplianceTag $labelName | Out-Null
}
# FOIA keywords
$policyName2 = "AutoApply – FOIA"
$ruleName2   = "FOIA Keywords"
$labelName2  = "FOIA Requests – 6 Years"
if (-not (Get-RetentionCompliancePolicy -Identity $policyName2 -ErrorAction SilentlyContinue)) {
  New-RetentionCompliancePolicy -Name $policyName2 -SharePointLocation All -OneDriveLocation All -ExchangeLocation All -TeamsChannelLocation All | Out-Null
}
if (-not (Get-RetentionComplianceRule -Identity $ruleName2 -ErrorAction SilentlyContinue)) {
  New-RetentionComplianceRule -Name $ruleName2 -Policy $policyName2 -ContentContainsSensitiveInformation @(
    @{ Name="Keywords"; operands=@("FOIA","Privacy Act","Disclosure","Request Number","Appeal") }
  ) -ApplyComplianceTag $labelName2 | Out-Null
}
