param(
  [ValidateSet('Global','USGov')]
  [string] $Environment = 'Global'
)
Import-Module ExchangeOnlineManagement -ErrorAction Stop
# Prompt for a user account to open an interactive authentication window.
$account = Read-Host 'Enter the UPN for authentication'
if ($Environment -eq 'USGov') {
  Connect-IPPSSession -UserPrincipalName $account -ConnectionUri 'https://ps.compliance.protection.office365.us/powershell-liveid/' -AzureADAuthorizationEndpointUri 'https://login.microsoftonline.us/common' | Out-Null
} else {
  Connect-IPPSSession -UserPrincipalName $account | Out-Null
}
