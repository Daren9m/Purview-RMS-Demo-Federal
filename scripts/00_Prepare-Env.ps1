param()

$tenantId = $env:M365_TENANT_ID
$appId = $env:M365_APP_ID
$thumb = $env:M365_APP_CERT_THUMBPRINT

if (-not $tenantId -or -not $appId -or -not $thumb) {
  throw "Missing required environment variables M365_TENANT_ID, M365_APP_ID, or M365_APP_CERT_THUMBPRINT. Configure repo secrets or set locally."
}

. .\scripts\utils\Connect-Graph.ps1 -TenantId $tenantId -AppId $appId -CertThumbprint $thumb
. .\scripts\utils\Connect-Compliance.ps1
