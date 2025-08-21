param(
  [ValidateSet('Global','USGov')]
  [string] $Environment = 'Global'
)
Import-Module Microsoft.Graph -ErrorAction Stop
# Import Microsoft.Graph.Beta.* modules as needed for beta cmdlets.
# Prompt for a user account to open an interactive authentication window.
$account = Read-Host 'Enter the UPN for authentication'
Connect-MgGraph -Environment $Environment -NoWelcome -LoginHint $account
Get-MgContext
