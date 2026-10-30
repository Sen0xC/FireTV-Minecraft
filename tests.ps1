. "$PSScriptRoot\common.ps1"
$errorsFound = @()
Get-ChildItem $PSScriptRoot -Filter '*.ps1' | ForEach-Object {
    $tokens=$null; $parseErrors=$null
    [Management.Automation.Language.Parser]::ParseFile($_.FullName,[ref]$tokens,[ref]$parseErrors) | Out-Null
    $errorsFound += @($parseErrors)
}
if ($errorsFound.Count) { throw ($errorsFound | Out-String) }
$config = Get-Config
if (@($config.uninstall).Count -or $null -ne $config.animationScale) { Write-Host 'Configuration personnalisee presente.' }
$fake = @([pscustomobject]@{package='org.example.video';type='utilisateur'},[pscustomobject]@{package='org.example.core';type='systeme'},[pscustomobject]@{package='com.amazon.service';type='utilisateur'})
function Must-Reject($c) {
    $rejected=$false
    try { Get-Plan $c $fake | Out-Null } catch { $rejected=$true }
    if (!$rejected) { throw 'Barriere de protection absente.' }
}
Must-Reject @{keep=@();uninstall=@('org.example.core')}
Must-Reject @{keep=@();uninstall=@('com.amazon.service')}
Must-Reject @{keep=@('org.example.video');uninstall=@('org.example.video')}
Must-Reject @{keep=@();uninstall=@('org.absent.app')}
if (@(Get-Plan @{keep=@();uninstall=@()} $fake).Count -ne 0) { throw 'Suppression implicite interdite.' }
if (@(Get-Plan @{keep=@();uninstall=@('org.example.video')} $fake).Count -ne 1) { throw 'Plan explicite invalide.' }
Write-Host 'OK : syntaxe PowerShell et 6 controles de plan. Aucun appel ADB.'
# Simuler stderr avec un vrai processus, sans lancer ADB ni joindre la TV.
& {
    function Get-Adb { return (Get-Process -Id $PID).Path }
    $result = Invoke-Adb @('-NoProfile','-Command','[Console]::Error.WriteLine("daemon starting"); [Console]::WriteLine("ok"); exit 0')
    if ($result -notmatch 'daemon starting' -or $result -notmatch 'ok') { throw 'Capture stdout/stderr incomplete.' }
    $failed = $false
    try { Invoke-Adb @('-NoProfile','-Command','[Console]::Error.WriteLine("failure"); exit 7') | Out-Null }
    catch { if ($_ -notmatch 'code 7') { throw }; $failed = $true }
    if (!$failed) { throw 'Code de sortie en erreur ignore.' }
    if ($ErrorActionPreference -ne 'Stop') { throw 'Preference appelante modifiee.' }
}
Write-Host 'OK : stderr accepte en cas de succes; code non nul toujours bloque.'
