param(
  [ValidateSet('Global','USGov')]
  [string] $Cloud = 'Global'
)

# Import-Module Microsoft.Graph -ErrorAction Stop
# Import Microsoft.Graph.Beta.* modules as needed for beta cmdlets.
# Use device code authentication to avoid dependency on a local browser or cached credentials.
Connect-MgGraph -Environment $Cloud -UseDeviceCode -NoWelcome

$graphContext = Get-MgContext


. .\scripts\utils\Connect-Compliance.ps1 -Environment $Cloud
