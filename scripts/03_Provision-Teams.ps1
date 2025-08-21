Import-Module Microsoft.Graph.Teams
Import-Module Microsoft.Graph.Users
$teamName = "Records Demo Team"
$team = Get-MgTeam -All | Where-Object { $_.DisplayName -eq $teamName } | Select-Object -First 1
if (-not $team) {
  $team = New-MgTeam -DisplayName $teamName -Description "Demo workspace" `
    -MemberSettings @{allowCreateUpdateChannels=$true} `
    -MessagingSettings @{allowUserEditMessages=$true} `
    -FunSettings @{allowGiphy=$false}
  Write-Host "Created team '$teamName'"
} else {
  Write-Host "Team '$teamName' already exists"
}
$teamId = $team.Id
$members = @("record.manager@contoso.com","contract.officer@contoso.com","foia.officer@contoso.com")
foreach ($m in $members) {
  try {
    $u = Get-MgUser -Filter "userPrincipalName eq '$m'" | Select-Object -First 1
    if ($u) {
      try {
        New-MgTeamMember -TeamId $teamId -AdditionalProperties @{
          "@odata.type" = "#microsoft.graph.aadUserConversationMember"
          roles = @("owner")
          user@odata.bind = "https://graph.microsoft.com/v1.0/users('$($u.Id)')"
        } | Out-Null
      } catch { Write-Warning "Member $m already added or cannot be added: $_" }
    }
  } catch { Write-Warning "Could not add $m: $_" }
}
$channels = "Contracts","FOIA","Program Planning","Compliance","HR"
$existingChans = Get-MgTeamChannel -TeamId $teamId -All
foreach ($c in $channels) {
  if (-not ($existingChans | Where-Object { $_.DisplayName -eq $c })) {
    New-MgTeamChannel -TeamId $teamId -DisplayName $c -MembershipType "standard" | Out-Null
  }
}
