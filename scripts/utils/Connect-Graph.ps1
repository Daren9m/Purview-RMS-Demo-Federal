param(
  [Parameter(Mandatory)] [string] $TenantId,
  [Parameter(Mandatory)] [string] $AppId,
  [Parameter(Mandatory)] [string] $CertThumbprint
)
Import-Module Microsoft.Graph -ErrorAction Stop
Connect-MgGraph -TenantId $TenantId -ClientId $AppId -CertificateThumbprint $CertThumbprint -NoWelcome
Select-MgProfile -Name beta
