param(
  [ValidateSet('Global','USGov')]
  [string] $Environment = 'Global'
)
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if ($Environment -eq 'USGov') {
  Connect-IPPSSession -ConnectionUri 'https://ps.compliance.protection.office365.us/powershell-liveid/' -AzureADAuthorizationEndpointUri 'https://login.microsoftonline.us/common' | Out-Null
} else {
  Connect-IPPSSession | Out-Null
}
