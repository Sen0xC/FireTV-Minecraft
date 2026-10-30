[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Journal, [switch]$Apply)
. "$PSScriptRoot\common.ps1"
$state = Get-Content -LiteralPath $Journal -Raw | ConvertFrom-Json
Assert-FireOS
if ($state.serial -ne (Get-Session).serial -or $state.fingerprint -ne (Shell @('getprop','ro.build.fingerprint'))) { throw 'Appareil ou firmware different : restauration refusee.' }
$changes = @($state.changes); [array]::Reverse($changes)
foreach ($r in $changes) {
    if ($r.kind -eq 'uninstall') { Write-Host "$($r.package) : reinstaller depuis la boutique. Recuperation des donnees non garantie."; continue }
    if ($r.kind -ne 'animation' -or $r.status -eq 'restored') { continue }
    if ($r.key -notin @('window_animation_scale','transition_animation_scale','animator_duration_scale') -or $r.old -notmatch '^(null|[0-9]+(\.[0-9]+)?)$') { throw 'Journal invalide.' }
    Write-Host "Restaurer $($r.key) = $($r.old)"
    if (!$Apply -or !(Confirm-Exact "RESTAURER $($r.key)")) { continue }
    if ($r.old -eq 'null') { Shell @('settings','delete','global',$r.key) | Out-Null }
    else { Shell @('settings','put','global',$r.key,$r.old) | Out-Null }
    if ((Shell @('settings','get','global',$r.key)) -ne $r.old) { throw 'Restauration non confirmee.' }
    $r.status='restored'; Save-Json $state $Journal
}
