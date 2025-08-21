<#
.SYNOPSIS
Loads synthetic demo content into M365 workloads for the Purview Records Management demo.
#>

param(
  [Parameter(Mandatory=$true)]
  [string]$ContentRoot,
  [string]$TeamName = "Records Demo Team",
  [string]$FromUpn = "record.manager@contoso.com"
)

Install-Module Microsoft.Graph.Users -Force
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Sites
Import-Module Microsoft.Graph.Drives
Import-Module Microsoft.Graph.Teams

function Get-DriveForSiteAlias {
  param([string]$Alias)
  $site = Get-MgSite -Search $Alias | Where-Object { $_.WebUrl -match "/sites/$Alias$" } | Select-Object -First 1
  if (-not $site) { Write-Warning "SharePoint site with alias '$Alias' not found."; return $null }
  $drive = Get-MgSiteDrive -SiteId $site.Id | Select-Object -First 1
  if (-not $drive) { Write-Warning "Drive for site '$Alias' not found."; return $null }
  return $drive
}

function Ensure-DriveFolder {
  param(
    [string]$DriveId,
    [string]$ParentId,
    [string]$Name
  )
  $child = Get-MgDriveItemChild -DriveId $DriveId -DriveItemId $ParentId -Filter "name eq '$Name' and folder ne null" -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $child) {
    $child = New-MgDriveItem -DriveId $DriveId -DriveItemId $ParentId -Name $Name -Folder @{}
  }
  return $child.Id
}

function Upload-FolderToDrive {
  param(
    [Parameter(Mandatory)][string]$FolderPath,
    [Parameter(Mandatory)][string]$Alias
  )
  $drive = Get-DriveForSiteAlias -Alias $Alias
  if (-not $drive) { return }
  $rootId = $drive.Root.Id
  Get-ChildItem -Path $FolderPath -Recurse -File | ForEach-Object {
    $relative = [System.IO.Path]::GetRelativePath($FolderPath, $_.DirectoryName)
    $parentId = $rootId
    if ($relative -and $relative -ne '.') {
      foreach ($part in $relative.Split([IO.Path]::DirectorySeparatorChar)) {
        if ($part) { $parentId = Ensure-DriveFolder -DriveId $drive.Id -ParentId $parentId -Name $part }
      }
    }
    Write-Host "Uploading $($_.Name) -> $Alias/$relative"
    $session = New-MgDriveItemUploadSession -DriveId $drive.Id -DriveItemId $parentId -FileName $_.Name -AdditionalProperties @{"@microsoft.graph.conflictBehavior"="replace"}
    Invoke-MgUploadFile -InputFile $_.FullName -UploadUrl $session.UploadUrl | Out-Null
  }
}

function Get-TeamIdByName {
  param([string]$DisplayName)
  $teams = Get-MgTeam -All
  ($teams | Where-Object {$_.DisplayName -eq $DisplayName} | Select-Object -First 1).Id
}

function Get-ChannelId {
  param([string]$TeamId, [string]$ChannelDisplayName)
  $channels = Get-MgTeamChannel -TeamId $TeamId -All
  ($channels | Where-Object {$_.DisplayName -eq $ChannelDisplayName} | Select-Object -First 1).Id
}

function Post-TeamsMessagesFromCsv {
  param([string]$CsvPath, [string]$TeamId, [string]$ChannelName)
  try {
    $chanId = Get-ChannelId -TeamId $TeamId -ChannelDisplayName $ChannelName
    if (-not $chanId) { Write-Warning "Channel '$ChannelName' not found in team."; return }
    $rows = Import-Csv $CsvPath
    foreach ($r in $rows) {
      $msg = @{
        "body" = @{"contentType"="text"; "content" = ("[{0}] {1}: {2}" -f $r.Timestamp, $r.User, $r.Message) }
      }
      New-MgTeamChannelMessage -TeamId $TeamId -ChannelId $chanId -BodyParameter $msg | Out-Null
    }
    Write-Host "Posted $(($rows|Measure-Object).Count) messages to #$ChannelName"
  } catch { Write-Warning "Failed to post messages from $CsvPath : $_" }
}

function Parse-EmlSimple {
  param([string]$Path)
  $headers = @{}
  $bodyLines = @()
  $inHeaders = $true
  $current = $null
  Get-Content $Path | ForEach-Object {
    if ($inHeaders) {
      if ($_ -match '^\s*$') { $inHeaders = $false; return }
      if ($_ -match '^[\t ]' -and $current) { $headers[$current] += " " + $_.Trim(); return }
      $parts = $_ -split ':\s*',2
      if ($parts.Count -eq 2) { $current = $parts[0]; $headers[$current] = $parts[1] }
    } else {
      $bodyLines += $_
    }
  }
  [PSCustomObject]@{
    From = $headers['From']
    To = $headers['To']
    Subject = $headers['Subject']
    Body = ($bodyLines -join "`n")
  }
}

# SharePoint uploads mapping
$map = @{
  "Contracts"        = "contracts"
  "FOIA"             = "foia"
  "Program-Planning" = "program-planning"
  "PDFs"             = "program-office"
  "Meeting-Notes"    = "program-office"
  "SharePoint-Docs"  = "program-office"
  "Transitory"       = "program-office"
}

foreach ($key in $map.Keys) {
  $folder = Join-Path $ContentRoot $key
  if (Test-Path $folder) {
    Upload-FolderToDrive -FolderPath $folder -Alias $map[$key]
  }
}

# Teams chat posts
$teamId = Get-TeamIdByName -DisplayName $TeamName
if ($teamId) {
  $teamsFolder = Join-Path $ContentRoot "Teams-Chats"
  if (Test-Path $teamsFolder) {
    Get-ChildItem $teamsFolder -Filter *.csv | ForEach-Object {
      $base = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
      $channel = $base -replace "-Channel$","" -replace "_"," "
      Post-TeamsMessagesFromCsv -CsvPath $_.FullName -TeamId $teamId -ChannelName $channel
    }
  }
} else {
  Write-Warning "Team '$TeamName' not found. Skipping Teams chat posting."
}

# Seed Emails
$emailsDir = Join-Path $ContentRoot "Emails"
if (Test-Path $emailsDir) {
  $from = $FromUpn
  Get-ChildItem $emailsDir -Filter *.eml | ForEach-Object {
    $eml = Parse-EmlSimple -Path $_.FullName
    if (-not $eml.Subject) { $eml.Subject = "Synthetic Demo Email" }
    if (-not $eml.To) { $eml.To = "contract.officer@contoso.com" }
    $toAddrs = @()
    foreach ($addr in ($eml.To -split ",")) {
      $toAddrs += @{ emailAddress = @{ address = $addr.Trim() } }
    }
    $message = @{
      subject = $eml.Subject
      body = @{ contentType = "Text"; content = ($eml.Body | Out-String) }
      toRecipients = $toAddrs
    }
    try {
      Send-MgUserMail -UserId $from -Message $message -SaveToSentItems | Out-Null
      Write-Host "Sent synthetic email: $($eml.Subject) -> $($eml.To)"
    } catch { Write-Warning "Failed sending email from $from: $_" }
  }
}
Write-Host "Synthetic content load complete."
