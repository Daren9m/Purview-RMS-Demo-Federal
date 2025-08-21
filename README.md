# Purview Records Demo (Federal)

A refactored, one-click demo for Microsoft Purview Records Management aligned to **NARA GRS** (6.1 Capstone, 4.2 FOIA, 1.1 Contracts, 1.3 Program Planning, 5.2 Transitory) and the **M‑19‑21 / M‑23‑07** electronic‑records posture.

## What you get
- **GRS‑aligned file plan & Capstone** (email permanent vs 7‑year).
- **Event‑based retention** (ContractClose, FOIACaseClosed).
- **Cross‑workload coverage** (Exchange, SharePoint, OneDrive, Teams).
- **Synthetic dataset** bundled as a zip (Word, Excel, PPTX, PDFs, emails, Teams chat CSVs, etc.).
- **GitHub Actions** to provision and load data automatically.

## Quick start (local)
1. Set environment variables `M365_TENANT_ID`, `M365_APP_ID`, and `M365_APP_CERT_THUMBPRINT`.
2. PowerShell (Windows):
   ```powershell
   pwsh -File .\scripts\00_Prepare-Env.ps1
   pwsh -File .\scripts\01_Seed-Users-And-Mail.ps1
   pwsh -File .\scripts\02_Provision-SharePointSites.ps1
   pwsh -File .\scripts\03_Provision-Teams.ps1
   pwsh -File .\scripts\05a_Create-Records-Labels.ps1
   pwsh -File .\scripts\05b_Create-Capstone-Email.ps1
   pwsh -File .\scripts\06a_Create-AutoApply-Policies.ps1
   Expand-Archive -Path .\synthetic-data\synthetic-content-federal-full.zip -DestinationPath .\synthetic-content -Force
   pwsh -File .\scripts\08_Load-SyntheticContent.ps1 -ContentRoot .\synthetic-content -TeamName "Records Demo Team" -FromUpn "record.manager@contoso.com"
   ```

## One‑click via GitHub Actions
- **Provision Purview Demo (Federal)**: provisions labels/policies + unzips and loads synthetic content.
- **Load Synthetic Content to M365**: loads synthetic content only (useful to refresh data).

### Required repo secrets
`M365_TENANT_ID`, `M365_APP_ID`, `M365_APP_CERT_THUMBPRINT`, `M365_APP_CERT_BASE64`, `M365_APP_CERT_PASSWORD`

## Demo storyline
1. Contracts doc auto‑labeled **Contracts – 6 Years** → declare record → attempt to edit (blocked).
2. Register **ContractClose** event → retention clock starts.
3. FOIA library with **FOIA Requests – 6 Years** & **FOIA Disclosure Logs – Permanent**.
4. Capstone mailboxes (**Permanent**) vs non‑Capstone (**7 Years**).
5. Teams channel posts appear and are searchable under retention scope.

## Teardown
```powershell
pwsh -File .\scripts\Teardown.ps1
```
