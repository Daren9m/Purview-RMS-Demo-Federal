# Event-based: Contract and FOIA
$eventType = "ContractClose"
$eventName = "ACQ-24-019 Closeout"
$eventDate = Get-Date "2025-09-30"
New-RetentionEventType -Name $eventType -Description "Contract closeout event" -ErrorAction SilentlyContinue | Out-Null
New-RetentionEvent -Name $eventName -EventType $eventType -EventDateTime $eventDate | Out-Null
$foiaType = "FOIACaseClosed"
$foiaName = "FOIA-2023-017 Closed"
$foiaDate = Get-Date "2023-12-31"
New-RetentionEventType -Name $foiaType -Description "FOIA case closed" -ErrorAction SilentlyContinue | Out-Null
New-RetentionEvent -Name $foiaName -EventType $foiaType -EventDateTime $foiaDate | Out-Null
Write-Host "Registered retention events for ContractClose and FOIACaseClosed."
