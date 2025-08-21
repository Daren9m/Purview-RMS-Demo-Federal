param([string]$Root = ".\config\synthetic-content")
Import-Module Microsoft.Graph.Sites
Import-Module Microsoft.Graph.Drives

$map = @{
  "Contracts" = "contracts"
  "FOIA" = "foia"
  "Program-Planning" = "program-planning"
}
foreach ($folder in Get-ChildItem $Root -Directory) {
  $alias = $map[$folder.Name]
  if (-not $alias) { continue }
  $site = Get-MgSite -Search $alias | Select-Object -First 1
  if (-not $site) { Write-Warning "Site $alias not found"; continue }
  $drive = Get-MgSiteDrive -SiteId $site.Id | Select-Object -First 1
  foreach ($f in Get-ChildItem $folder.FullName -File) {
    Write-Host "Uploading $($f.Name) to site $alias"
    New-MgDriveItemUpload -DriveId $drive.Id -Name $f.Name -FilePath $f.FullName -ConflictBehavior replace | Out-Null
  }
}
