param(
  [ValidateSet('Global','USGov')]
  [string] $Environment = 'Global'
)
# Import-Module Microsoft.Graph -ErrorAction Stop
# Import Microsoft.Graph.Beta.* modules as needed for beta cmdlets.
# Use device code authentication to avoid dependency on a local browser or cached credentials.
Connect-MgGraph -Environment $Environment -UseDeviceCode -NoWelcome
Get-MgContext
