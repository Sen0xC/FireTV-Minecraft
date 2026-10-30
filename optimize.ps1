[CmdletBinding()]
param([switch]$Apply)
. "$PSScriptRoot\common.ps1"
if (!$Apply) { & "$PSScriptRoot\preview.ps1"; return }
Assert-FireOS
$c = Get-Config
if ($null -ne $c.animationScale -and [string]$c.animationScale -notin @('0','0.5','1')) { throw 'animationScale doit etre null, 0, 0.5 ou 1.' }
$plan = @(Get-Plan $c @(Get-Inventory))
$plan | Format-Table -AutoSize
$dir = Join-Path $PSScriptRoot 'journal'
New-Item -ItemType Directory -Force $dir | Out-Null
$journal = Join-Path $dir ("{0}-{1}.json" -f (Get-Date -Format yyyyMMdd-HHmmss),[guid]::NewGuid().ToString('N'))
$state = [ordered]@{ serial=(Get-Session).serial; fingerprint=(Shell @('getprop','ro.build.fingerprint')); changes=@() }
foreach ($item in $plan) {
    if (!(Confirm-Exact "SUPPRIMER $($item.package) ET SES DONNEES")) { continue }
    # Recontroler le type et la liste blanche juste avant chaque suppression.
    $fresh = @(Get-Plan (Get-Config) @(Get-Inventory))
    if ($item.package -cnotin @($fresh | ForEach-Object { $_.package })) { throw 'Plan modifie : relancer la simulation.' }
    $record = [ordered]@{kind='uninstall'; package=$item.package; status='pending'; undo='Reinstaller depuis la boutique; donnees non garanties'}
    $state.changes += $record; Save-Json $state $journal
    $result = Shell @('pm','uninstall','--user','0',$item.package)
    if ($result -notmatch '^Success$') { throw "Echec : $result. Consulter le journal." }
    $record.status='applied'; Save-Json $state $journal
    if (@(Get-Inventory | Where-Object { $_.package -ceq $item.package }).Count) { throw 'Package toujours present : arret.' }
    if (!(Confirm-Exact 'TELECOMMANDE WIFI PARAMETRES ET LECTURE OK')) { return }
}
if ($null -ne $c.animationScale) {
    foreach ($key in @('window_animation_scale','transition_animation_scale','animator_duration_scale')) {
        $old = Shell @('settings','get','global',$key)
        if ($old -notmatch '^(null|[0-9]+(\.[0-9]+)?)$') { throw "Valeur non reconnue pour $key : $old" }
        Write-Host "$key : $old -> $($c.animationScale)"
        if (!(Confirm-Exact "MODIFIER $key")) { continue }
        $record = [ordered]@{kind='animation'; key=$key; old=$old; value=[string]$c.animationScale; status='pending'}
        $state.changes += $record; Save-Json $state $journal
        Shell @('settings','put','global',$key,[string]$c.animationScale) | Out-Null
        if ((Shell @('settings','get','global',$key)) -ne [string]$c.animationScale) { throw 'Reglage refuse : consulter restore.ps1.' }
        $record.status='applied'; Save-Json $state $journal
    }
}
Write-Host "Journal : $journal. Mesurer de nouveau avec diagnostic.ps1 -Label apres."
