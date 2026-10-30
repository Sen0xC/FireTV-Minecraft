[CmdletBinding()]
param([string]$Label='avant')
. "$PSScriptRoot\common.ps1"
Assert-FireOS
if ($Label -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Label invalide.' }
$dir = Join-Path $PSScriptRoot 'reports'
New-Item -ItemType Directory -Force $dir | Out-Null
$props = [ordered]@{}
foreach ($p in @('ro.product.model','ro.product.device','ro.product.manufacturer','ro.build.display.id','ro.build.version.incremental','ro.build.version.release','ro.build.version.sdk','ro.build.fingerprint','ro.serialno')) { $props[$p] = Shell @('getprop',$p) }
$inventory = @(Get-Inventory)
$c = Get-Config
foreach ($a in $inventory) {
    $entry = $c.labels.PSObject.Properties[$a.package]
    if ($entry) { $a.name = $entry.Value; $a.labelSource = 'Configuration utilisateur' }
    if ($a.type -eq 'systeme') { $a.recommendation = 'ne pas toucher' }
}
$report = [ordered]@{ timestamp=(Get-Date).ToString('o'); serial=(Get-Session).serial; properties=$props; generation='A confirmer dans la table Amazon avec le modele exact'; storage=(Shell @('df','-k','/data')); ram=(Shell @('cat','/proc/meminfo')); memory=(Shell @('dumpsys','meminfo')); apps=$inventory }
$stem = "$Label-$(Get-Date -Format yyyyMMdd-HHmmss)"
Save-Json $report (Join-Path $dir "$stem.json")
$inventory | Export-Csv (Join-Path $dir "$stem-apps.csv") -NoTypeInformation -Encoding UTF8
$inventory | Format-Table name,package,type,enabled,recommendation -AutoSize
Write-Host "Rapports : $dir. Choisissez les packages a conserver dans apps.json."
