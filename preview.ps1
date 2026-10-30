[CmdletBinding()]
param()
. "$PSScriptRoot\common.ps1"
$c = Get-Config
Write-Host 'SIMULATION : aucun changement sur la TV.'
if (@($c.uninstall).Count -eq 0 -and $null -eq $c.animationScale) { Write-Host 'Aucune modification configuree.'; return }
Assert-FireOS
@(Get-Plan $c @(Get-Inventory)) | Format-Table -AutoSize
if ($null -ne $c.animationScale) { Write-Host "Animations proposees : $($c.animationScale), apres sauvegarde des valeurs actuelles." }
