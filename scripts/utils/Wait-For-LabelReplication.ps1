param([string]$LabelName, [int]$TimeoutMinutes = 20)
$start = Get-Date
do {
  Start-Sleep -Seconds 30
  try {
    $label = Get-Label -Identity $LabelName -ErrorAction Stop
    if ($label) { return $true }
  } catch { }
} while ((Get-Date) -lt $start.AddMinutes($TimeoutMinutes))
throw "Label '$LabelName' not visible after $TimeoutMinutes minutes."
