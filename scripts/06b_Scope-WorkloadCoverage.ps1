$policies = Get-RetentionCompliancePolicy
$rules = Get-RetentionComplianceRule

$summary = foreach ($p in $policies) {
  [PSCustomObject]@{
    Policy = $p.Name
    ExchangeLocation = if ($p.ExchangeLocation) { ($p.ExchangeLocation -join ';') } else { $null }
    ExcludedExchange = if ($p.ExcludedExchangeLocation) { ($p.ExcludedExchangeLocation -join ';') } else { $null }
    SharePoint = if ($p.SharePointLocation) { ($p.SharePointLocation -join ';') } else { $null }
    OneDrive = if ($p.OneDriveLocation) { ($p.OneDriveLocation -join ';') } else { $null }
    TeamsChat = if ($p.TeamsChatLocation) { ($p.TeamsChatLocation -join ';') } else { $null }
    TeamsChannel = if ($p.TeamsChannelLocation) { ($p.TeamsChannelLocation -join ';') } else { $null }
  }
}
$summary | Format-Table -AutoSize
