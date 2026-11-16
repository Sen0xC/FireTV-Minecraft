# Compile le code officiel StreamPlus deja telecharge dans tools/streamplus/source.
# Necessite les outils prepares par build-launcher.ps1 et android-api34.jar.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root=$PSScriptRoot
$src=(Get-ChildItem (Join-Path $root 'tools\streamplus\source') -Directory | Select-Object -First 1).FullName
$build=Join-Path $root 'tools\streamplus\build'
$cache=Join-Path $root 'tools\voxel-build'
$android=Join-Path $cache 'android-api34.jar'
$aapt=Join-Path $cache 'aapt2\aapt2.exe'
$r8=Join-Path $cache 'r8.jar'
$java=(Get-Command java).Source
function Run($exe,[string[]]$arguments) {
    $prior=$ErrorActionPreference
    try {
        $ErrorActionPreference='Continue'; $PSNativeCommandUseErrorActionPreference=$false
        $out=@(& $exe @arguments 2>&1); $code=$LASTEXITCODE
    } finally { $ErrorActionPreference=$prior }
    $out | ForEach-Object { Write-Host "$_" }
    if ($code -ne 0) { throw "Echec $exe ($code)" }
}
$prior=$ErrorActionPreference
try { $ErrorActionPreference='Continue'; $props=@(& $java -XshowSettings:properties -version 2>&1) }
finally { $ErrorActionPreference=$prior }
$jdk=(@($props | ForEach-Object { "$_" } | Where-Object { $_ -match '^\s*java.home\s*=' })[0] -replace '^\s*java.home\s*=\s*','').Trim()
foreach ($dir in @($build,"$build\gen","$build\classes","$build\dex","$build\assets",(Join-Path $root 'dist'))) { New-Item -ItemType Directory -Force $dir | Out-Null }
Copy-Item "$src\assets\*" "$build\assets" -Recurse -Force
'{}' | Set-Content "$build\assets\web\config.json" -Encoding ASCII
foreach ($file in @('plugins.js','player-plugins.js','personal.css')) { '' | Set-Content "$build\assets\web\$file" -Encoding ASCII }
Run $aapt @('compile','--dir',"$src\res",'-o',"$build\resources.zip")
Run $aapt @('link','-o',"$build\unsigned.apk",'-I',$android,'--manifest',"$src\AndroidManifest.xml",'-A',"$build\assets",'--java',"$build\gen",'--min-sdk-version','26','--target-sdk-version','34','--version-code','1','--version-name','1.0',"$build\resources.zip")
$pkgdir="$build\gen\com\hugo\streamplus"
New-Item -ItemType Directory -Force $pkgdir | Out-Null
'package com.hugo.streamplus; final class Plugins { static final String[] CLASSES = {}; }' | Set-Content "$pkgdir\Plugins.java" -Encoding ASCII
$sources=@(Get-ChildItem "$src\src","$build\gen" -Recurse -Filter '*.java' | ForEach-Object { $_.FullName })
Run (Join-Path $jdk 'bin\javac.exe') (@('-encoding','UTF-8','--release','11','-classpath',$android,'-d',"$build\classes")+$sources)
Run (Join-Path $jdk 'bin\jar.exe') @('cf',"$build\classes.jar",'-C',"$build\classes",'.')
Run $java @('-cp',$r8,'com.android.tools.r8.D8','--release','--min-api','26','--lib',$android,'--lib',$jdk,'--output',"$build\dex","$build\classes.jar")
$zip=[IO.Compression.ZipFile]::Open("$build\unsigned.apk",[IO.Compression.ZipArchiveMode]::Update)
try {
    # AAPT2 autonome sous Windows peut garder des antislashs dans les noms d'assets.
    # Android attend des chemins ZIP avec '/'; sinon la WebView ne trouve pas index.html.
    foreach ($entry in @($zip.Entries | Where-Object { $_.FullName.Contains('\') })) {
        $normalized=$zip.CreateEntry($entry.FullName.Replace('\','/'))
        $inputStream=$entry.Open(); $outputStream=$normalized.Open()
        try { $inputStream.CopyTo($outputStream) } finally { $inputStream.Dispose(); $outputStream.Dispose() }
        $entry.Delete()
    }
    Get-ChildItem "$build\dex" -Filter '*.dex' | ForEach-Object { [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$_.FullName,$_.Name) | Out-Null }
}
finally { $zip.Dispose() }
$key=Join-Path $cache 'streamplus-local.keystore'
if (!(Test-Path $key)) { Run (Join-Path $jdk 'bin\keytool.exe') @('-genkeypair','-keystore',$key,'-storepass','android','-keypass','android','-alias','streamplus','-keyalg','RSA','-keysize','2048','-validity','10000','-dname','CN=StreamPlus Local') }
$apk=Join-Path $root 'dist\StreamPlus.apk'
Run (Join-Path $jdk 'bin\jarsigner.exe') @('-keystore',$key,'-storepass','android','-keypass','android','-sigalg','SHA256withRSA','-digestalg','SHA-256','-signedjar',$apk,"$build\unsigned.apk",'streamplus')
Run (Join-Path $jdk 'bin\jarsigner.exe') @('-verify',$apk)
Run $aapt @('dump','badging',$apk)
Get-FileHash $apk -Algorithm SHA256
