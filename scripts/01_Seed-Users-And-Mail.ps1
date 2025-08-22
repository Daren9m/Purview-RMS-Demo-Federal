param([string]$UsersCsv = ".\config\users.csv")

# Ensure Microsoft Graph modules are available
Install-Module Microsoft.Graph.Users -Force
Install-Module Microsoft.Graph.Groups -Force
Install-Module Microsoft.Graph.Identity.DirectoryManagement -Force
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.Identity.DirectoryManagement

# Create or get E5 license group and assign E5 licenses
$licenseGroupName = "E5 License Group"
$licenseGroup = Get-MgGroup -Filter "displayName eq '$licenseGroupName'" -ErrorAction SilentlyContinue
if (-not $licenseGroup) {
    $licenseGroup = New-MgGroup -DisplayName $licenseGroupName -MailEnabled:$false -MailNickname "E5LicenseGroup" -SecurityEnabled
    Write-Host "Created license group $licenseGroupName"
}
$e5Sku = (Get-MgSubscribedSku | Where-Object { $_.SkuPartNumber -eq "ENTERPRISEPREMIUM" } | Select-Object -First 1).SkuId
if ($e5Sku -and $licenseGroup) {
    try {
        Set-MgGroupLicense -GroupId $licenseGroup.Id -AddLicenses @{SkuId=$e5Sku} -RemoveLicenses @() | Out-Null
        Write-Host "E5 license linked to group $licenseGroupName"
    } catch {
        Write-Warning "Failed assigning license to group: $_"
    }
} else {
    Write-Warning "E5 license SKU not found; ensure tenant has E5 licenses."
}

# Ensure users exist and add them to the license group
$users = Import-Csv $UsersCsv
foreach ($u in $users) {
    $user = Get-MgUser -Filter "userPrincipalName eq '$($u.UserPrincipalName)'" -ErrorAction SilentlyContinue
    if (-not $user) {
        $pwd = @{ Password = (New-Guid).Guid + "!1a"; ForceChangePasswordNextSignIn = $true }
        $params = @{
            DisplayName       = $u.DisplayName
            Department        = $u.Department
            UserPrincipalName = $u.UserPrincipalName
            MailNickname      = ($u.UserPrincipalName.Split('@')[0])
            PasswordProfile   = $pwd
            AccountEnabled    = $true
        }
        try {
            $user = New-MgUser @params
            Write-Host "Created user $($u.UserPrincipalName)"
        } catch {
            Write-Warning "Failed creating user $($u.UserPrincipalName): $_"
            continue
        }
    }

    if ($licenseGroup) {
        try {
            Add-MgGroupMember -GroupId $licenseGroup.Id -DirectoryObjectId $user.Id -ErrorAction Stop
            Write-Host "Added $($u.UserPrincipalName) to $licenseGroupName"
        } catch {
            Write-Warning "Failed adding $($u.UserPrincipalName) to group: $_"
        }
    }
}

# Seed mail
$from = "record.manager@contoso.com"
$to = "contract.officer@contoso.com"
$msg = @{
  subject = "RFP ACQ-24-019 Statement of Work and Closeout"
  body = @{ contentType = "Text"; content = "Please review the attached RFP and prepare award memo. Closeout date is 2025-09-30." }
  toRecipients = @(@{emailAddress=@{address=$to}})
}
try {
  $fromUser = Get-MgUser -Filter "userPrincipalName eq '$from'" -ErrorAction SilentlyContinue
  $toUser = Get-MgUser -Filter "userPrincipalName eq '$to'" -ErrorAction SilentlyContinue
  if ($fromUser -and $toUser) {
    Send-MgUserMail -UserId $from -Message $msg -SaveToSentItems
    Write-Host "Seed mail sent from $from to $to"
  } else {
    Write-Warning "Skipping seed mail; required accounts are missing."
  }
} catch {
  Write-Warning "Failed sending seed mail: $_"
}

