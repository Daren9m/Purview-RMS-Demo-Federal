param(
    [string]$UsersCsv = ".\config\users.csv",
    [string]$LicenseGroupName = "E5 License Group",
    [switch]$CreateLicenseGroup,
    [string]$LogFile = ".\logs\01_Seed-Users.log"
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

# Ensure Microsoft Graph modules are available
foreach ($m in @("Microsoft.Graph.Users","Microsoft.Graph.Groups","Microsoft.Graph.Identity.DirectoryManagement")) {
    try {
        Install-Module $m -Force
        Import-Module $m
        Write-Log -Level "INFO" -Action "Module loaded" -Details $m
    } catch {
        Write-Log -Level "Warning" -Action "Module load failed" -Details "$m : $_"
    }
}

# Create or get E5 license group and assign E5 licenses
$licenseGroup = Get-MgGroup -Filter "displayName eq '$LicenseGroupName'" -ErrorAction SilentlyContinue
if (-not $licenseGroup -and $CreateLicenseGroup) {
    try {
        $licenseGroup = New-MgGroup -DisplayName $LicenseGroupName -MailEnabled:$false -MailNickname ($LicenseGroupName -replace '\s','') -SecurityEnabled
        Write-Log -Level "INFO" -Action "Created license group" -Details $LicenseGroupName
    } catch {
        Write-Log -Level "Warning" -Action "Failed creating license group" -Details $_
    }
} elseif (-not $licenseGroup) {
    Write-Log -Level "Warning" -Action "License group not found" -Details $LicenseGroupName
}

$e5Sku = Get-MgSubscribedSku | Where-Object { $_.SkuPartNumber -eq "ENTERPRISEPREMIUM" } | Select-Object -First 1
if ($e5Sku) {
    $users = Import-Csv $UsersCsv
    $availableLicenses = $e5Sku.PrepaidUnits.Enabled - $e5Sku.ConsumedUnits
    Write-Log -Level "INFO" -Action "E5 license availability" -Details "Available: $availableLicenses"
    if ($availableLicenses -lt $users.Count) {
        Write-Log -Level "Warning" -Action "Insufficient E5 licenses" -Details "Available: $availableLicenses; Required: $($users.Count)"
    }
    if ($licenseGroup) {
        $licenseDetails = Get-MgGroupLicenseDetail -GroupId $licenseGroup.Id -ErrorAction SilentlyContinue
        $hasLicense = $false
        if ($licenseDetails) { $hasLicense = $licenseDetails.SkuId -contains $e5Sku.SkuId }
        if (-not $hasLicense -and $availableLicenses -gt 0) {
            try {
                Set-MgGroupLicense -GroupId $licenseGroup.Id -AddLicenses @{SkuId=$e5Sku.SkuId} -RemoveLicenses @() | Out-Null
                Write-Log -Level "INFO" -Action "E5 license linked to group" -Details $LicenseGroupName
            } catch {
                Write-Log -Level "Warning" -Action "Failed assigning license to group" -Details $_
            }
        } elseif ($hasLicense) {
            Write-Log -Level "INFO" -Action "Group already has E5 license" -Details $LicenseGroupName
        } else {
            Write-Log -Level "Warning" -Action "No available E5 licenses to assign" -Details ""
        }
    }
} else {
    Write-Log -Level "Warning" -Action "E5 license SKU not found" -Details "Ensure tenant has E5 licenses"
    $users = Import-Csv $UsersCsv
}

# Ensure users exist and add them to the license group
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
            Write-Log -Level "INFO" -Action "Created user" -Details $u.UserPrincipalName
        } catch {
            Write-Log -Level "Warning" -Action "Failed creating user" -Details "$($u.UserPrincipalName): $_"
            continue
        }
    }

    if ($licenseGroup) {
        try {
            Add-MgGroupMember -GroupId $licenseGroup.Id -DirectoryObjectId $user.Id -ErrorAction Stop
            Write-Log -Level "INFO" -Action "Added user to group" -Details $u.UserPrincipalName
        } catch {
            Write-Log -Level "Warning" -Action "Failed adding user to group" -Details "$($u.UserPrincipalName): $_"
        }
    }
}
