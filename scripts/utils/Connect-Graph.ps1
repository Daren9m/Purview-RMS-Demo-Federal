param(
  [ValidateSet('Global','USGov')]
  [string] $Environment = 'Global'
)
Import-Module Microsoft.Graph -ErrorAction Stop
# Import Microsoft.Graph.Beta.* modules as needed for beta cmdlets.
Connect-MgGraph -Environment $Environment -NoWelcome
Get-MgContext
