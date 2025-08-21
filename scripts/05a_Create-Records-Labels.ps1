param([string]$FilePlan = ".\config\fileplan.json")
$plan = Get-Content $FilePlan -Raw | ConvertFrom-Json
foreach ($item in $plan) {
  $existing = Get-Label -Identity $item.Name -ErrorAction SilentlyContinue
  if ($existing) { continue }
  $contentType = if ($item.ContentType) { $item.ContentType } else { "All" }
  if ($item.RetentionDurationDays) { $duration = "$($item.RetentionDurationDays) Days" }
  elseif ($item.RetentionDurationYears -lt 0) { $duration = "Unlimited" }
  else { $duration = "$($item.RetentionDurationYears) Years" }
  $trigger = if ($item.RetentionTrigger -eq "EventDate") { "Event" } else { "WhenCreated" }
  New-Label -Name $item.Name `
    -RetentionAction $item.Action `
    -RetentionDuration $duration `
    -RetentionType "KeepAndDelete" `
    -ContentType $contentType `
    -AdvancedSettings @{ "retentionTrigger" = $trigger; "eventType" = $item.EventType }
}
try { Set-Label -Identity "FOIA Requests – 6 Years" -IsRecordLabel $true } catch {}
try { Set-Label -Identity "Contracts – 6 Years" -IsRecordLabel $true -AutoDelete $true } catch {}
