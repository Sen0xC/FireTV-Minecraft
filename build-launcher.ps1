# Construction locale uniquement. Ne contacte jamais la Fire TV.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$cache = Join-Path $root 'tools\voxel-build'
$build = Join-Path $root 'launcher\build'
$dist = Join-Path $root 'dist'
foreach ($dir in @($cache,$build,$dist)) { New-Item -ItemType Directory -Force $dir | Out-Null }
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Fetch([string]$Name,[string]$Url) {
    $path = Join-Path $cache $Name
    if (!(Test-Path $path)) {
        Write-Host "Telechargement : $Name"
        $partial = "$path.partial"
        Invoke-WebRequest $Url -OutFile $partial -UseBasicParsing
        Move-Item -LiteralPath $partial -Destination $path -Force
    }
    return $path
}
function Run([string]$Exe,[string[]]$Arguments) {
    $prior = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $PSNativeCommandUseErrorActionPreference = $false
        $output = @(& $Exe @Arguments 2>&1)
        $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $prior }
    $output | ForEach-Object { Write-Host "$_" }
    if ($code -ne 0) { throw "$Exe : echec ($code)" }
}
$java = (Get-Command java -ErrorAction Stop).Source
# Le raccourci Oracle javapath n'expose pas toujours keytool/jarsigner.
$prior = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    $PSNativeCommandUseErrorActionPreference = $false
    $properties = @(& $java -XshowSettings:properties -version 2>&1)
} finally { $ErrorActionPreference = $prior }
$homeLine = @($properties | ForEach-Object { "$_" } | Where-Object { $_ -match '^\s*java.home\s*=' })
if ($homeLine.Count -ne 1) { throw 'JDK introuvable : installer JDK 17.' }
$jdkPath = ($homeLine[0] -replace '^\s*java.home\s*=\s*','').Trim()
$keytool = Join-Path $jdkPath 'bin\keytool.exe'
$jarsigner = Join-Path $jdkPath 'bin\jarsigner.exe'
if (!(Test-Path $keytool) -or !(Test-Path $jarsigner)) { throw 'JDK complet 17 requis.' }
$maven = 'https://repo.maven.apache.org/maven2'
$google = 'https://dl.google.com/dl/android/maven2'
$jars = @()
foreach ($artifact in @(
    @('compiler.jar',"$maven/org/jetbrains/kotlin/kotlin-compiler-embeddable/1.9.24/kotlin-compiler-embeddable-1.9.24.jar"),
    @('stdlib.jar',"$maven/org/jetbrains/kotlin/kotlin-stdlib/1.9.24/kotlin-stdlib-1.9.24.jar"),
    @('script-runtime.jar',"$maven/org/jetbrains/kotlin/kotlin-script-runtime/1.9.24/kotlin-script-runtime-1.9.24.jar"),
    @('reflect.jar',"$maven/org/jetbrains/kotlin/kotlin-reflect/1.6.10/kotlin-reflect-1.6.10.jar"),
    @('daemon.jar',"$maven/org/jetbrains/kotlin/kotlin-daemon-embeddable/1.9.24/kotlin-daemon-embeddable-1.9.24.jar"),
    @('trove.jar',"$maven/org/jetbrains/intellij/deps/trove4j/1.0.20200330/trove4j-1.0.20200330.jar"),
    @('annotations.jar',"$maven/org/jetbrains/annotations/13.0/annotations-13.0.jar")
)) { $jars += Fetch $artifact[0] $artifact[1] }
$android = Fetch 'android-api28.jar' "$maven/org/robolectric/android-all/9-robolectric-4913185-2/android-all-9-robolectric-4913185-2.jar"
$r8 = Fetch 'r8.jar' "$google/com/android/tools/r8/8.3.37/r8-8.3.37.jar"
$aaptZip = Fetch 'aapt2.jar' "$google/com/android/tools/build/aapt2/8.6.1-11315950/aapt2-8.6.1-11315950-windows.jar"
$aaptDir = Join-Path $cache 'aapt2'
if (!(Test-Path (Join-Path $aaptDir 'aapt2.exe'))) { [IO.Compression.ZipFile]::ExtractToDirectory($aaptZip,$aaptDir) }
$aapt = Join-Path $aaptDir 'aapt2.exe'
$assets = Join-Path $build 'assets'
$res = Join-Path $build 'res\drawable'
New-Item -ItemType Directory -Force $assets,$res | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'assets\voxel-landscape.jpg') -Destination $assets -Force
Copy-Item -LiteralPath (Join-Path $root 'assets\voxel-forest.png') -Destination $assets -Force
# Icone et banniere originales derivees de notre propre paysage.
Add-Type -AssemblyName System.Drawing
$source = [Drawing.Image]::FromFile((Join-Path $root 'assets\voxel-forest.png'))
foreach ($spec in @(@('icon',96,96),@('banner',320,180))) {
    $bitmap = New-Object Drawing.Bitmap ([int]$spec[1]),([int]$spec[2])
    $g = [Drawing.Graphics]::FromImage($bitmap)
    $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.DrawImage($source,0,0,[int]$spec[1],[int]$spec[2])
    $bitmap.Save((Join-Path $res "$($spec[0]).png"),[Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bitmap.Dispose()
}
$source.Dispose()
Write-Host 'Compilation des ressources et du code Kotlin...'
$compiled = Join-Path $build 'resources.zip'
Run $aapt @('compile','--dir',(Join-Path $build 'res'),'-o',$compiled)
$unsigned = Join-Path $build 'unsigned.apk'
Run $aapt @('link','-o',$unsigned,'--manifest',(Join-Path $root 'launcher\AndroidManifest.xml'),'-I',$android,'-A',$assets,$compiled)
$classes = Join-Path $build 'classes.jar'
Run $java @('-cp',($jars -join ';'),'org.jetbrains.kotlin.cli.jvm.K2JVMCompiler','-no-stdlib','-no-reflect','-jvm-target','1.8','-classpath',"$android;$(Join-Path $cache 'stdlib.jar');$(Join-Path $cache 'annotations.jar')",'-d',$classes,(Join-Path $root 'launcher\src\MainActivity.kt'))
$dexDir = Join-Path $build 'dex'
New-Item -ItemType Directory -Force $dexDir | Out-Null
Run $java @('-cp',$r8,'com.android.tools.r8.D8','--release','--min-api','22','--lib',$android,'--lib',$jdkPath,'--output',$dexDir,$classes,(Join-Path $cache 'stdlib.jar'),(Join-Path $cache 'annotations.jar'))
$archive = [IO.Compression.ZipFile]::Open($unsigned,[IO.Compression.ZipArchiveMode]::Update)
try {
    Get-ChildItem $dexDir -Filter 'classes*.dex' | ForEach-Object {
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$_.FullName,$_.Name,[IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
} finally { $archive.Dispose() }
$key = Join-Path $cache 'local.keystore'
if (!(Test-Path $key)) {
    Run $keytool @('-genkeypair','-keystore',$key,'-alias','voxel','-storepass','android','-keypass','android','-keyalg','RSA','-keysize','2048','-validity','10000','-dname','CN=Accueil Voxel Local')
}
$apk = Join-Path $dist 'AccueilVoxel.apk'
Run $jarsigner @('-keystore',$key,'-storepass','android','-keypass','android','-sigalg','SHA256withRSA','-digestalg','SHA-256','-signedjar',$apk,$unsigned,'voxel')
Run $jarsigner @('-verify',$apk)
Run $aapt @('dump','badging',$apk)
Get-FileHash $apk -Algorithm SHA256 | Format-List
Write-Host "APK construit : $apk. Aucune installation sur la TV effectuee."
