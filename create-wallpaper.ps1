# Dessin original procedural, sans texture ni asset provenant de Minecraft.
Add-Type -AssemblyName System.Drawing
$dir = Join-Path $PSScriptRoot 'assets'
New-Item -ItemType Directory -Force $dir | Out-Null
$small = New-Object Drawing.Bitmap 320,180
$g = [Drawing.Graphics]::FromImage($small)
$g.Clear([Drawing.Color]::FromArgb(109,181,225))
function Block($x,$y,$w,$h,$color) {
    $brush = New-Object Drawing.SolidBrush ([Drawing.ColorTranslator]::FromHtml($color))
    $g.FillRectangle($brush,$x,$y,$w,$h); $brush.Dispose()
}
Block 244 20 18 18 '#ffe9a6'
foreach ($cloud in @(@(20,28),@(110,17),@(184,43))) { Block $cloud[0] $cloud[1] 34 5 '#e3f1f1'; Block ($cloud[0]+6) ($cloud[1]-4) 18 4 '#e3f1f1' }
for ($x=0;$x -lt 320;$x+=8) {
    $h = 100 + 8*[math]::Floor(2*[math]::Sin($x/47.0))
    Block $x $h 8 (180-$h) '#547f66'
    $near = 135 + 8*[math]::Floor(2*[math]::Sin($x/31.0+1))
    Block $x $near 8 (180-$near) '#77563d'; Block $x $near 8 4 '#619443'
    for ($y=$near+8;$y -lt 180;$y+=8) { if ((($x+$y)%24) -eq 0) { Block $x $y 4 3 '#896548' } }
}
Block 0 163 56 17 '#747d7c'; Block 0 160 48 4 '#8d9691'; Block 8 170 12 3 '#606b6d'; Block 32 166 8 3 '#606b6d'
$g.Dispose()
$large = New-Object Drawing.Bitmap 1920,1080
$out = [Drawing.Graphics]::FromImage($large)
$out.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$out.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
$out.DrawImage($small,0,0,1920,1080)
$large.Save((Join-Path $dir 'voxel-landscape.jpg'),[Drawing.Imaging.ImageFormat]::Jpeg)
$out.Dispose(); $small.Dispose(); $large.Dispose()
Write-Host 'Fond original cree : assets/voxel-landscape.jpg'
