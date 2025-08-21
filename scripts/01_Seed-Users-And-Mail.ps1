param([string]$UsersCsv = ".\config\users.csv")
Install-Module Microsoft.Graph.Users -Force
Import-Module Microsoft.Graph.Users
$users = Import-Csv $UsersCsv
foreach ($u in $users) {
  $user = Get-MgUser -Filter "userPrincipalName eq '$($u.UserPrincipalName)'" -ErrorAction SilentlyContinue
  if (-not $user) { Write-Host "User $($u.UserPrincipalName) must pre-exist or be created per-tenant policy." }
}
# Seed mail
$from = "record.manager@contoso.com"
$to = "contract.officer@contoso.com"
$msg = @{
  subject = "RFP ACQ-24-019 Statement of Work and Closeout"
  body = @{ contentType = "Text"; content = "Please review the attached RFP and prepare award memo. Closeout date is 2025-09-30." }
  toRecipients = @(@{emailAddress=@{address=$to}})
}
try {
  $fromUser = Get-MgUser -Filter "userPrincipalName eq '$from'" -ErrorAction SilentlyContinue
  $toUser = Get-MgUser -Filter "userPrincipalName eq '$to'" -ErrorAction SilentlyContinue
  if ($fromUser -and $toUser) {
    Send-MgUserMail -UserId $from -Message $msg -SaveToSentItems
    Write-Host "Seed mail sent from $from to $to"
  } else {
    Write-Warning "Skipping seed mail; required accounts are missing."
  }
} catch {
  Write-Warning "Failed sending seed mail: $_"
}
