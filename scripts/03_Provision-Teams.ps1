Import-Module Microsoft.Graph.Teams
Import-Module Microsoft.Graph.Users
$team = New-MgTeam -DisplayName "Records Demo Team" -Description "Demo workspace" `
  -MemberSettings @{allowCreateUpdateChannels=$true} `
  -MessagingSettings @{allowUserEditMessages=$true} `
  -FunSettings @{allowGiphy=$false}
$teamId = $team.Id
$members = @("record.manager@contoso.com","contract.officer@contoso.com","foia.officer@contoso.com")
foreach ($m in $members) {
  try {
    $u = Get-MgUser -Filter "userPrincipalName eq '$m'" | Select-Object -First 1
    if ($u) {
      New-MgTeamMember -TeamId $teamId -AdditionalProperties @{
        "@odata.type" = "#microsoft.graph.aadUserConversationMember"
        roles = @("owner")
        user@odata.bind = "https://graph.microsoft.com/v1.0/users('$($u.Id)')"
      } | Out-Null
    }
  } catch { Write-Warning "Could not add $m: $_" }
}
$channels = "Contracts","FOIA","Program Planning","Compliance","HR"
foreach ($c in $channels) {
  New-MgTeamChannel -TeamId $teamId -DisplayName $c -MembershipType "standard" | Out-Null
}
