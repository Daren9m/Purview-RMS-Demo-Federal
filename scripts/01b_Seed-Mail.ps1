param(
    [string]$From = "record.manager@contoso.com",
    [string]$To   = "contract.officer@contoso.com",
    [string]$LogFile = ".\logs\01b_Seed-Mail.log"
)

$logDir = Split-Path $LogFile
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

function Write-Log {
    param([string]$Level, [string]$Action, [string]$Details = "")
    $entry = [PSCustomObject]@{
        Timestamp = (Get-Date).ToString("o")
        Level     = $Level
        Action    = $Action
        Details   = $Details
    }
    $entry | ConvertTo-Json -Compress | Add-Content -Path $LogFile
    if ($Level -eq "Warning") {
        Write-Warning "$Action $Details"
    } else {
        Write-Host "$Action $Details"
    }
}

$runInfo = [PSCustomObject]@{
    Timestamp = (Get-Date).ToString("o")
    AdminUser = [Environment]::UserName
    Machine   = [Environment]::MachineName
    OS        = [System.Environment]::OSVersion.VersionString
    Script    = $MyInvocation.MyCommand.Path
}
$runInfo | ConvertTo-Json -Compress | Set-Content -Path $LogFile

foreach ($m in @("Microsoft.Graph.Users","Microsoft.Graph.Mail")) {
    try {
        Install-Module $m -Force
        Import-Module $m
        Write-Log -Level "INFO" -Action "Module loaded" -Details $m
    } catch {
        Write-Log -Level "Warning" -Action "Module load failed" -Details "$m : $_"
    }
}

$msg = @{
  subject = "RFP ACQ-24-019 Statement of Work and Closeout"
  body = @{ contentType = "Text"; content = "Please review the attached RFP and prepare award memo. Closeout date is 2025-09-30." }
  toRecipients = @(@{emailAddress=@{address=$To}})
}
try {
  $fromUser = Get-MgUser -Filter "userPrincipalName eq '$From'" -ErrorAction SilentlyContinue
  $toUser = Get-MgUser -Filter "userPrincipalName eq '$To'" -ErrorAction SilentlyContinue
  if ($fromUser -and $toUser) {
    Send-MgUserMail -UserId $From -Message $msg -SaveToSentItems
    Write-Log -Level "INFO" -Action "Seed mail sent" -Details "$From -> $To"
  } else {
    Write-Log -Level "Warning" -Action "Skipping seed mail" -Details "Required accounts missing"
  }
} catch {
  Write-Log -Level "Warning" -Action "Failed sending seed mail" -Details $_
}
