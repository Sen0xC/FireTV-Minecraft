# Retire uniquement la redirection Home on Fire; ne desinstalle aucun package.
[CmdletBinding()]
param([switch]$Apply)
. "$PSScriptRoot\common.ps1"
Assert-FireOS
$current = Shell @('settings','get','secure','enabled_accessibility_services')
$kept = @($current -split ':' | Where-Object {
    $_ -and $_ -ne 'null' -and $_ -cne 'io.github.toolicious.homeonfire/.HijackService' -and $_ -cne 'io.github.toolicious.homeonfire/io.github.toolicious.homeonfire.HijackService'
})
Write-Host 'Retirer uniquement Home on Fire des services actifs; conserver les autres.'
Write-Host 'Le bouton Maison et le demarrage automatique reviennent au comportement Amazon.'
if (!$Apply) { Write-Host 'SIMULATION. Utiliser -Apply pour appliquer avec confirmation.'; return }
if (!(Confirm-Exact 'ARRETER REDIRECTION MAISON')) { return }
if ($kept.Count) { Shell @('settings','put','secure','enabled_accessibility_services',($kept -join ':')) | Out-Null }
else {
    Shell @('settings','delete','secure','enabled_accessibility_services') | Out-Null
    # L'etat initial de ce PC/appareil etait sans service (voir reports/home-before.json).
    Shell @('settings','put','secure','accessibility_enabled','0') | Out-Null
}
Shell @('pm','revoke','io.github.toolicious.homeonfire','android.permission.WRITE_SECURE_SETTINGS') | Out-Null
Write-Host 'Redirection arretee. Cissou''s TV reste ouvrable manuellement.'
