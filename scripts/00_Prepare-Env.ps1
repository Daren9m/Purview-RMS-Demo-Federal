param(
  [ValidateSet('Global','USGov')]
  [string] $Cloud = 'Global'
)

$graphContext = . .\scripts\utils\Connect-Graph.ps1 -Environment $Cloud
. .\scripts\utils\Connect-Compliance.ps1 -Environment $Cloud
