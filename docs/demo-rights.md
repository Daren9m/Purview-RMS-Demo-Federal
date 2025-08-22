# Demo Rights

The table below lists the recommended permissions for each step of the demo.

| Step | Script | Required Rights | Notes |
| ---- | ------ | --------------- | ----- |
| 0 | `00_Prepare-Env.ps1` | Global Administrator; Compliance Administrator | Establishes connections to Graph and Purview. |
| 1 | `01_Seed-Users.ps1` | Global Administrator | Creates demo users and assigns E5 licenses. |
| 1b | `01b_Seed-Mail.ps1` | Mail.Send delegated permission; run after directory replication | Sends the initial seed email between demo accounts. |
| 2 | `02_Provision-SharePointSites.ps1` | SharePoint Administrator | Creates required SharePoint sites. |
| 3 | `03_Provision-Teams.ps1` | Teams Administrator | Creates the Teams workspace and channels, adds demo users as owners. |
| 5a | `05a_Create-Records-Labels.ps1` | Records Management or Compliance Administrator role | Creates retention labels and publishes them to SharePoint sites. |
| 5b | `05b_Create-Capstone-Email.ps1` | Exchange Administrator; Records Management or Compliance Administrator | Configures capstone email retention policies. |
| 6a | `06a_Create-AutoApply-Policies.ps1` | Records Management or Compliance Administrator | Creates keyword-based auto-apply policies. |
| 6b | `06b_Scope-WorkloadCoverage.ps1` | Records Management read access | Displays the workloads included in each retention policy. |
| 7 | `07_Demo-Flows.ps1` | Records Management or Compliance Administrator | Registers retention events for the demo storyline. |
| 8 | `08_Load-SyntheticContent.ps1` | SharePoint and Teams membership; Mail.Send permission for `FromUpn` | Uploads synthetic files and posts sample Teams chats. |

Demo users such as `record.manager@contoso.com`, `contract.officer@contoso.com`, and `foia.officer@contoso.com` should be assigned the roles above as needed to execute their respective parts of the demo.
