# Contracts keyword auto-apply across workloads
$policyName = "AutoApply – Contracts"
$ruleName   = "Contracts Keywords"
$labelName  = "Contracts – 6 Years"

$policy = Get-RetentionCompliancePolicy -Identity $policyName -ErrorAction SilentlyContinue
if (-not $policy) {
  $policy = New-RetentionCompliancePolicy -Name $policyName -SharePointLocation All -OneDriveLocation All -ExchangeLocation All -TeamsChannelLocation All
}

$rule = Get-RetentionComplianceRule -Identity $ruleName -ErrorAction SilentlyContinue
if (-not $rule) {
  New-RetentionComplianceRule -Name $ruleName -Policy $policy.Name -ContentContainsSensitiveInformation @(
    @{ Name="Keywords"; operands=@("RFP","Acquisition","Solicitation","Award","Closeout","SOW") }
  ) -ApplyComplianceTag $labelName
}

# FOIA auto-apply based on keywords
$policyName2 = "AutoApply – FOIA"
$ruleName2   = "FOIA Keywords"
$labelName2  = "FOIA Requests – 6 Years"

$policy2 = Get-RetentionCompliancePolicy -Identity $policyName2 -ErrorAction SilentlyContinue
if (-not $policy2) {
  $policy2 = New-RetentionCompliancePolicy -Name $policyName2 -SharePointLocation All -OneDriveLocation All -ExchangeLocation All -TeamsChannelLocation All
}
$rule2 = Get-RetentionComplianceRule -Identity $ruleName2 -ErrorAction SilentlyContinue
if (-not $rule2) {
  New-RetentionComplianceRule -Name $ruleName2 -Policy $policyName2 -ContentContainsSensitiveInformation @(
    @{ Name="Keywords"; operands=@("FOIA","Privacy Act","Disclosure","Request Number","Appeal") }
  ) -ApplyComplianceTag $labelName2
}
