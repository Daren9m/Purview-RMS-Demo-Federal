param([string]$UsersCsv = ".\config\users.csv")
Import-Module Microsoft.Graph.Users
$users = Import-Csv $UsersCsv
foreach ($u in $users) {
  $user = Get-MgUser -Filter "userPrincipalName eq '$($u.UserPrincipalName)'" -ErrorAction SilentlyContinue
  if (-not $user) { Write-Host "User $($u.UserPrincipalName) must pre-exist or be created per-tenant policy." }
}

# Seed mail to Contracting Officer (to demonstrate Exchange coverage/Capstone later)
$from = "record.manager@contoso.com"
$to = "contract.officer@contoso.com"
$msg = @{
  subject = "RFP ACQ-24-019 Statement of Work and Closeout"
  body = @{ contentType = "Text"; content = "Please review the attached RFP and prepare award memo. Closeout date is 2025-09-30." }
  toRecipients = @(@{emailAddress=@{address=$to}})
}
New-MgUserSendMail -UserId $from -Message $msg -SaveToSentItems
