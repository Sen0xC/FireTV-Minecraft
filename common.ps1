Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:Root = $PSScriptRoot
function Save-Json($Value, $Path) { $Value | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $Path -Encoding UTF8 }
function Get-Adb {
    $local = Join-Path $script:Root 'tools\platform-tools\adb.exe'
    if (Test-Path $local) { return $local }
    $cmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
    if (Test-Path $sdk) { return $sdk }
    throw 'ADB introuvable. Voir setup.ps1 et README.md.'
}
function Invoke-Adb([string[]]$Arguments) {
    $exe = Get-Adb
    # Windows PowerShell transforme stderr en ErrorRecord, meme si ADB reussit.
    # Capturer ces messages et juger uniquement le code de sortie du processus.
    $savedPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $PSNativeCommandUseErrorActionPreference = $false
        $out = @(& $exe @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $savedPreference
    }
    if ($exitCode -ne 0) { throw "ADB (code $exitCode) : $($out -join "`n")" }
    return ($out -join "`n").Trim()
}
function Get-Session {
    $path = Join-Path $script:Root 'session.json'
    if (!(Test-Path $path)) { throw 'Executer setup.ps1 -Connect -DeviceIP ... et confirmer Fire OS.' }
    $s = Get-Content $path -Raw | ConvertFrom-Json
    if ($s.os -ne 'FireOS' -or $s.serial -notmatch '^\d{1,3}(\.\d{1,3}){3}:\d{1,5}$') { throw 'Session Android non autorisee.' }
    return $s
}
function Shell([string[]]$Command) {
    $s = Get-Session
    Invoke-Adb -Arguments (@('-s', $s.serial, 'shell') + $Command)
}
function Assert-FireOS {
    if ((Invoke-Adb -Arguments @('-s',(Get-Session).serial,'get-state')) -ne 'device') { throw 'Appareil non autorise ou hors ligne.' }
    $api = Shell @('getprop','ro.build.version.sdk')
    $brand = Shell @('getprop','ro.product.manufacturer')
    if ($api -notmatch '^\d+$' -or [int]$api -lt 22 -or $brand -notmatch '(?i)amazon') { throw 'Fire OS Android non confirme : arret.' }
}
function Confirm-Exact([string]$Text) { return ((Read-Host "Pour confirmer, saisir exactement : $Text") -ceq $Text) }
function Get-Inventory {
    $all = Shell @('pm','list','packages','--user','0')
    $users = (Shell @('pm','list','packages','-3','--user','0')) -split '\r?\n'
    $systems = (Shell @('pm','list','packages','-s','--user','0')) -split '\r?\n'
    $enabled = (Shell @('pm','list','packages','-e','--user','0')) -split '\r?\n'
    if ($all -match '(?i)error|exception|unknown option') { throw "Inventaire indisponible : $all" }
    foreach ($line in ($all -split '\r?\n')) {
        if ($line -notmatch '^package:([a-zA-Z0-9_]+(\.[a-zA-Z0-9_]+)+)$') { continue }
        $pkg = $Matches[1]
        $type = 'inconnu'
        if ($users -contains $line) { $type = 'utilisateur' }
        if ($systems -contains $line) { $type = 'systeme' }
        [pscustomobject]@{ package=$pkg; name='Non resolu'; type=$type; enabled=($enabled -contains $line); function='Non verifiee'; risk='Dependances possibles; donnees perdues si desinstallation'; recommendation='conserver'; labelSource='Renseigner apps.json apres verification sur le televiseur' }
    }
}
function Get-Config {
    $c = Get-Content (Join-Path $script:Root 'apps.json') -Raw | ConvertFrom-Json
    foreach ($p in @($c.keep) + @($c.uninstall)) {
        if ($p -notmatch '^[a-zA-Z0-9_]+(\.[a-zA-Z0-9_]+)+$') { throw "Identifiant invalide : $p" }
    }
    return $c
}
function Get-Plan($Config, $Inventory) {
    foreach ($pkg in $Config.uninstall) {
        $app = @($Inventory | Where-Object { $_.package -ceq $pkg })
        if ($app.Count -ne 1) { throw "Package absent ou ambigu : $pkg" }
        # Barriere volontairement conservative, meme pour les services classes utilisateur.
        if ($app[0].type -ne 'utilisateur' -or $pkg -match '^(com\.(amazon|android|google)|android)(\.|$)' -or $Config.keep -contains $pkg) { throw "Package protege : $pkg" }
        [pscustomobject]@{ package=$pkg; action='desinstaller'; consequence='Suppression application ET donnees; restauration non garantie' }
    }
}
