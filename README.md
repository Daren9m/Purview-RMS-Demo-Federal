# Purview Records Demo (Federal)

End-to-end Microsoft Purview Records demo aligned with NARA GRS and the federal transition to electronic records (M-19-21, updated by M-23-07). It provisions synthetic content across Exchange, SharePoint, OneDrive, and Teams; creates retention labels (including Capstone/GRS 6.1); applies auto-apply policies; demonstrates event-based retention; and shows disposition.

## What’s included
- **GRS-aligned file plan**: GRS 6.1 (Email/Capstone), GRS 4.2 (FOIA), GRS 1.1/1.3 (Contracts/Program Planning), GRS 5.2 (Transitory).
- **Capstone email**: Permanent for designated Capstone mailboxes; 7-year temporary for all others.
- **Event-based retention**: Contract close-out, FOIA case close.
- **Coverage**: Policies for Exchange, SharePoint, OneDrive, Teams.
- **Synthetic content**: Contracts, FOIA, Program Planning sample files.

## Prerequisites
- PowerShell 7.4+
- Modules:
  - `Microsoft.Graph`
  - `ExchangeOnlineManagement`
- Entra ID app registration with certificate auth and the necessary Graph application permissions
- Demo UPNs exist and are licensed (`config/users.csv`)

## Quick start
1. Copy `config/tenants.example.json` to `config/tenants.json` and fill in your values.
2. Run scripts in order:
   ```powershell
   pwsh -File .\scripts\00_Prepare-Env.ps1
   pwsh -File .\scripts\01_Seed-Users-And-Mail.ps1
   pwsh -File .\scripts\03_Provision-Teams.ps1
   pwsh -File .\scripts\04_Upload-Content.ps1
   pwsh -File .\scripts\05a_Create-Records-Labels.ps1
   pwsh -File .\scripts\05b_Create-Capstone-Email.ps1
   pwsh -File .\scripts\06a_Create-AutoApply-Policies.ps1
   pwsh -File .\scripts\06b_Scope-WorkloadCoverage.ps1   # optional: useful for screenshots
   pwsh -File .\scripts\07_Demo-Flows.ps1                # optional: event-based example
   ```
3. Open the Purview portal to verify labels, disposition, and audit.

## Demo storyline
- Upload a contract doc; auto-label applies “Contracts – 6 Years.” Declare record; show immutability.
- Register the `ContractClose` event; show event-based start.
- Show FOIA library: “FOIA Requests – 6 Years” and “FOIA Disclosure Logs – Permanent.”
- Email: open a Capstone mailbox (permanent) vs a non-Capstone mailbox (7-year).
- Run `06b_Scope-WorkloadCoverage.ps1` to demonstrate cross-workload coverage.

## Teardown
```powershell
pwsh -File .\scripts\Teardown.ps1
```

## Notes
- Label replication can take time; `scripts/utils/Wait-For-LabelReplication.ps1` is included.
- If your tenant restricts site or team creation, create those manually; run content and policy scripts only.
