param([string]$ConfigPath = ".\config\tenants.json")
if (-not (Test-Path $ConfigPath)) {
  throw "Missing tenants.json. Copy config\tenants.json.template to config\tenants.json and fill values, or use Actions secrets."
}
$cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json
. .\scripts\utils\Connect-Graph.ps1 -TenantId $cfg.TenantId -AppId $cfg.AppId -CertThumbprint $cfg.CertThumbprint
. .\scripts\utils\Connect-Compliance.ps1
