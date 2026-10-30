[CmdletBinding()]
param([switch]$InstallTools, [switch]$Connect, [string]$DeviceIP, [ValidateRange(1,65535)][int]$Port=5555)
. "$PSScriptRoot\common.ps1"
if ($InstallTools) {
    Write-Host 'Source officielle et licence : https://developer.android.com/tools/releases/platform-tools'
    if (Confirm-Exact 'INSTALLER OUTILS') {
        $dest = Join-Path $PSScriptRoot 'tools'
        New-Item -ItemType Directory -Force $dest | Out-Null
        $zip = Join-Path $dest 'platform-tools.zip'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip' -OutFile $zip -UseBasicParsing
        Expand-Archive -LiteralPath $zip -DestinationPath $dest -Force
        Get-FileHash $zip -Algorithm SHA256 | Format-List
    }
}
try { Write-Host "ADB : $(Get-Adb)" } catch { Write-Host $_; Write-Host 'Simulation : telecharger les outils officiels avec -InstallTools.' }
Write-Host 'Lire sur la TV : Parametres > Ma Fire TV > A propos (modele, version OS, Reseau/IP).'
Write-Host 'Fire OS seulement : activer Options developpeur > Debogage ADB. Au besoin, selectionner 7 fois le nom de l appareil dans A propos.'
if (!$Connect) { Write-Host 'Aucune connexion effectuee. Utiliser -Connect -DeviceIP 192.168.x.x.'; return }
$ip = $null
if (![Net.IPAddress]::TryParse($DeviceIP, [ref]$ip) -or $ip.AddressFamily -ne 'InterNetwork') { throw 'Adresse IPv4 requise.' }
$b = $ip.GetAddressBytes()
if (!($b[0] -eq 10 -or ($b[0] -eq 192 -and $b[1] -eq 168) -or ($b[0] -eq 172 -and $b[1] -ge 16 -and $b[1] -le 31))) { throw 'Adresse privee du reseau local requise.' }
if (!(Confirm-Exact 'FIRE OS CONFIRME')) { throw 'OS inconnu ou Vega : aucune commande ADB envoyee.' }
$serial = "${DeviceIP}:$Port"
if (!(Confirm-Exact "CONNECTER $serial")) { return }
Invoke-Adb -Arguments @('connect',$serial) | Write-Host
Write-Host 'Accepter la cle RSA affichee sur votre TV, puis appuyer sur Entree.'
Read-Host | Out-Null
if ((Invoke-Adb -Arguments @('-s',$serial,'get-state')) -ne 'device') { throw 'Connexion non autorisee.' }
Save-Json ([ordered]@{serial=$serial; os='FireOS'}) (Join-Path $PSScriptRoot 'session.json')
Assert-FireOS
Write-Host 'Connexion et controle Android reussis. Executer diagnostic.ps1.'
