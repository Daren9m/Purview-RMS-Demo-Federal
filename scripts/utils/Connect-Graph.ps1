param(
  [Parameter(Mandatory)] [string] $TenantId,
  [Parameter(Mandatory)] [string] $AppId,
  [Parameter(Mandatory)] [string] $CertThumbprint
)
Import-Module Microsoft.Graph -ErrorAction Stop
# Import Microsoft.Graph.Beta.* modules as needed for beta cmdlets.
Connect-MgGraph -TenantId $TenantId -ClientId $AppId -CertificateThumbprint $CertThumbprint -NoWelcome
