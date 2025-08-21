param([switch]$RemoveLabels=$false)

# Rules and policies to remove
$rules = @(
  "Contracts Keywords","FOIA Keywords",
  "Capstone – Apply Permanent to Capstone Mailboxes",
  "Agency Email – Apply 7 Years to Non-Capstone"
)
foreach ($r in $rules) {
  try { Remove-RetentionComplianceRule -Identity $r -Confirm:$false } catch {}
}

$policies = @(
  "AutoApply – Contracts","AutoApply – FOIA",
  "Capstone – Email Permanent","Agency Email – 7 Years"
)
foreach ($p in $policies) {
  try { Remove-RetentionCompliancePolicy -Identity $p -Confirm:$false } catch {}
}

if ($RemoveLabels) {
  $labels = @(
    "Capstone Email – Permanent","Agency Email – 7 Years",
    "FOIA Disclosure Logs – Permanent","FOIA Requests – 6 Years",
    "Contracts – 6 Years","Program Planning – 3 Years","Transitory Records – 90 Days"
  )
  foreach ($l in $labels) {
    try { Remove-Label -Identity $l -Confirm:$false } catch {}
  }
}

Write-Host "Teardown complete."
