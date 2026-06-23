# Renders store screenshots with System.Drawing (no browser required).
# UTF-8

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$Root = Split-Path $PSScriptRoot -Parent
$PluginStatic = Join-Path $Root "com.rkfsociety.d6gifkeys.sdPlugin\static"
$OutDir = Join-Path $PSScriptRoot "output"
$IconPath = Join-Path $PluginStatic "icon.png"
$demoGif = Join-Path $PluginStatic "demo.gif"
$defaultJpg = Join-Path $PluginStatic "default.jpg"

if (Test-Path $OutDir) { Remove-Item $OutDir -Recurse -Force }
New-Item -ItemType Directory -Path $OutDir | Out-Null

function New-Font([float]$size, [System.Drawing.FontStyle]$style = [System.Drawing.FontStyle]::Regular) {
    return New-Object System.Drawing.Font("Segoe UI", $size, $style)
}

function New-Canvas([int]$w, [int]$h) {
    $bmp = New-Object System.Drawing.Bitmap $w, $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    return @{ Bitmap = $bmp; G = $g }
}

function Save-Canvas($c, [string]$name) {
    $path = Join-Path $OutDir $name
    $c.Bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $c.G.Dispose()
    $c.Bitmap.Dispose()
    return $path
}

function Fill-Gradient($g, $rect, $c1, $c2) {
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, $c1, $c2, 45
    $g.FillRectangle($brush, $rect)
    $brush.Dispose()
}

function Draw-RoundedRect($g, $brush, $pen, $x, $y, $w, $h, $r) {
    if ($r -le 0) {
        if ($brush) { $g.FillRectangle($brush, $x, $y, $w, $h) }
        if ($pen) { $g.DrawRectangle($pen, $x, $y, $w, $h) }
        return
    }
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc($x, $y, $r, $r, 180, 90)
    $path.AddArc($x + $w - $r, $y, $r, $r, 270, 90)
    $path.AddArc($x + $w - $r, $y + $h - $r, $r, $r, 0, 90)
    $path.AddArc($x, $y + $h - $r, $r, $r, 90, 90)
    $path.CloseFigure()
    if ($brush) { $g.FillPath($brush, $path) }
    if ($pen) { $g.DrawPath($pen, $path) }
    $path.Dispose()
}

function Draw-Key($g, $x, $y, $size, $gifPath, $bgPath, $title, [bool]$hot, [double]$bgOpacity = 0.5) {
    $border = if ($hot) { [System.Drawing.Color]::FromArgb(255, 78, 187, 228) } else { [System.Drawing.Color]::FromArgb(255, 58, 58, 72) }
    $pen = New-Object System.Drawing.Pen $border, 2
    $bgBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 37, 37, 48))
    Draw-RoundedRect $g $bgBrush $pen $x $y $size $size 12
    $pen.Dispose(); $bgBrush.Dispose()

    $inner = 4
    $ix = $x + $inner; $iy = $y + $inner; $is = $size - 2 * $inner
    $clip = New-Object System.Drawing.Drawing2D.GraphicsPath
    $clip.AddArc($ix, $iy, 12, 12, 180, 90)
    $clip.AddArc($ix + $is - 12, $iy, 12, 12, 270, 90)
    $clip.AddArc($ix + $is - 12, $iy + $is - 12, 12, 12, 0, 90)
    $clip.AddArc($ix, $iy + $is - 12, 12, 12, 90, 90)
    $clip.CloseFigure()
    $state = $g.Save()
    $g.SetClip($clip)

    if ($bgPath -and (Test-Path $bgPath)) {
        $bg = [System.Drawing.Image]::FromFile($bgPath)
        $g.DrawImage($bg, $ix, $iy, $is, $is)
        $bg.Dispose()
        $overlay = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb([int](255 * (1 - $bgOpacity)), 0, 0, 0))
        $g.FillRectangle($overlay, $ix, $iy, $is, $is)
        $overlay.Dispose()
    }

    if ($gifPath -and (Test-Path $gifPath)) {
        $gif = [System.Drawing.Image]::FromFile($gifPath)
        $scale = [Math]::Min($is / $gif.Width, $is / $gif.Height)
        $dw = [int]($gif.Width * $scale); $dh = [int]($gif.Height * $scale)
        $gx = $ix + ($is - $dw) / 2; $gy = $iy + ($is - $dh) / 2
        $g.DrawImage($gif, $gx, $gy, $dw, $dh)
        $gif.Dispose()
    }

    $g.Restore($state)
    $clip.Dispose()

    if ($title) {
        $font = New-Font 9 Bold
        $sf = New-Object System.Drawing.StringFormat
        $sf.Alignment = [System.Drawing.StringAlignment]::Center
        $sf.LineAlignment = [System.Drawing.StringAlignment]::Far
        $shadow = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(180, 0, 0, 0))
        $rect = New-Object System.Drawing.RectangleF ($x + 2), ($y + 2), ($size - 4), ($size - 8)
        $g.DrawString($title, $font, $shadow, $rect, $sf)
        $white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
        $rect2 = New-Object System.Drawing.RectangleF $x, $y, ($size - 4), ($size - 10)
        $g.DrawString($title, $font, $white, $rect2, $sf)
        $font.Dispose(); $shadow.Dispose(); $white.Dispose(); $sf.Dispose()
    }
}

function Draw-SettingsPanel($g) {
    $labelFont = New-Font 9
    $labelBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 154, 154, 154))
    $valueBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 216, 216, 216))
    $boxBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 61, 61, 61))
    $boxPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 150, 150, 150))
    $accent = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 78, 187, 228))

    $rows = @(
        @{ L = [string][char]0x0424 + [char]0x0430 + [char]0x0439 + [char]0x043B + " GIF"; V = "demo.gif"; Y = 72 },
        @{ L = [string][char]0x0438 + [char]0x043B + [char]0x0438 + " URL"; V = "https://example.com/cat.gif"; Y = 110 },
        @{ L = [string][char]0x0421 + [char]0x043A + [char]0x043E + [char]0x0440 + [char]0x043E + [char]0x0441 + [char]0x0442 + [char]0x044C + " (%)"; V = "150%"; Y = 148; Bar = 132 },
        @{ L = [string][char]0x0422 + [char]0x0430 + [char]0x0439 + [char]0x043C + [char]0x0438 + [char]0x043D + [char]0x0433; V = [string][char]0x0424 + [char]0x0438 + [char]0x043A + [char]0x0441 + [char]0x002E + " FPS"; Y = 186 },
        @{ L = "FPS (1-30)"; V = "15"; Y = 224 },
        @{ L = [string][char]0x0424 + [char]0x043E + [char]0x043D + " (%)"; V = "50%"; Y = 262; Bar = 110 },
        @{ L = [string][char]0x041F + [char]0x043E + [char]0x0434 + [char]0x043F + [char]0x0438 + [char]0x0441 + [char]0x044C; V = "LIVE"; Y = 300 }
    )

    foreach ($row in $rows) {
        $g.DrawString($row.L, $labelFont, $labelBrush, 16, $row.Y)
        if ($row.Bar) {
            $g.FillRectangle($boxBrush, 112, $row.Y + 8, 220, 6)
            $g.FillRectangle($accent, 112, $row.Y + 8, $row.Bar, 6)
            $g.DrawString($row.V, (New-Font 9 Bold), $accent, 340, $row.Y + 2)
        } elseif ($row.L -like "*URL*") {
            Draw-RoundedRect $g $boxBrush $boxPen 112 $row.Y 292 24 0
            $g.DrawString($row.V, (New-Font 8), $valueBrush, 118, $row.Y + 5)
        } else {
            Draw-RoundedRect $g $boxBrush $boxPen 112 $row.Y 180 24 0
            $g.DrawString($row.V, $labelFont, $valueBrush, 120, $row.Y + 5)
        }
    }

    $prevLabel = [string][char]0x041F + [char]0x0440 + [char]0x0435 + [char]0x0432 + [char]0x044C + [char]0x044E
    $g.DrawString($prevLabel, $labelFont, $labelBrush, 16, 348)
    $prev = [System.Drawing.Image]::FromFile($demoGif)
    $g.DrawImage($prev, 112, 348, 126, 126)
    $prev.Dispose()
    $g.DrawRectangle($boxPen, 112, 348, 126, 126)
    Draw-RoundedRect $g $boxBrush $boxPen 250 396 70 24 0
    $clear = [string][char]0x041E + [char]0x0447 + [char]0x0438 + [char]0x0441 + [char]0x0442 + [char]0x0438 + [char]0x0442 + [char]0x044C
    $g.DrawString($clear, (New-Font 8), $valueBrush, 258, 401)
}

# 01 settings
$c = New-Canvas 420 680
$g = $c.G
$g.Clear([System.Drawing.Color]::FromArgb(255, 45, 45, 45))

$badgeBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 78, 187, 228))
$g.FillRectangle($badgeBrush, 300, 10, 100, 22)
$dark = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 17, 17, 17))
$g.DrawString("D6 GIF Keys v1.6", (New-Font 8 Bold), $dark, 308, 13)

$headFont = New-Font 10
$headBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 216, 216, 216))
$linePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 61, 61, 61))
$g.DrawLine($linePen, 16, 48, 130, 48)
$heading = "GIF " + [char]0x043D + [char]0x0430 + [char]0x0020 + [char]0x043A + [char]0x043D + [char]0x043E + [char]0x043F + [char]0x043A + [char]0x0435
$g.DrawString($heading, $headFont, $headBrush, 140, 38)
$g.DrawLine($linePen, 250, 48, 404, 48)

Draw-SettingsPanel $g
Save-Canvas $c "01-settings-panel.png" | Out-Null

# 02 keys
$c = New-Canvas 520 400
$g = $c.G
Fill-Gradient $g ([System.Drawing.Rectangle]::FromLTRB(0, 0, 520, 400)) `
    ([System.Drawing.Color]::FromArgb(255, 30, 30, 36)) `
    ([System.Drawing.Color]::FromArgb(255, 18, 18, 24))

$titleFont = New-Font 13 Bold
$subFont = New-Font 9
$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 232, 232, 245))
$gray = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 122, 122, 136))
$g.DrawString("FIFINE AmpliGame D6", $titleFont, $white, 150, 36)
$sub = "GIF-" + [char]0x043A + [char]0x043B + [char]0x044E + [char]0x0447 + [char]0x0438 + " D6"
$g.DrawString($sub, $subFont, $gray, 195, 62)

$deckBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 13, 13, 16))
$deckPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 42, 42, 50))
Draw-RoundedRect $g $deckBrush $deckPen 68 92 384 232 16

$kx = 84; $ky = 108; $gap = 10; $ks = 96
Draw-Key $g $kx $ky $ks $demoGif $defaultJpg "LIVE" $true
Draw-Key $g ($kx + $ks + $gap) $ky $ks $demoGif $defaultJpg "" $true
$cntFont = New-Font 22 Bold
$cntBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 204, 204, 204))
$g.DrawString("42", $cntFont, $cntBrush, ($kx + 2*($ks+$gap) + 34), ($ky + 32))
$g.DrawString("URL", $subFont, $gray, ($kx + $ks + $gap), ($ky + 2*($ks+$gap) + 38))

$legendFont = New-Font 8
$accent = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 78, 187, 228))
$green = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 126, 217, 87))
$g.FillEllipse($accent, 180, 348, 8, 8)
$gifLbl = "GIF-" + [char]0x043A + [char]0x043D + [char]0x043E + [char]0x043F + [char]0x043A + [char]0x0430
$g.DrawString($gifLbl, $legendFont, $gray, 194, 343)
$g.FillEllipse($green, 280, 348, 8, 8)
$cntLbl = [char]0x0421 + [char]0x0447 + [char]0x0451 + [char]0x0442 + [char]0x0447 + [char]0x0438 + [char]0x043A
$g.DrawString($cntLbl, $legendFont, $gray, 294, 343)

Save-Canvas $c "02-d6-keys.png" | Out-Null

# 03 hero
$c = New-Canvas 1200 675
$g = $c.G
$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 232, 232, 245))
$gray = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 122, 122, 136))
$cntBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 204, 204, 204))
$labelFont = New-Font 9
$labelBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 154, 154, 154))
$valueBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 216, 216, 216))
$headFont = New-Font 10
$headBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 216, 216, 216))
$linePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 61, 61, 61))
$heading = "GIF " + [char]0x043D + [char]0x0430 + [char]0x0020 + [char]0x043A + [char]0x043D + [char]0x043E + [char]0x043F + [char]0x043A + [char]0x0435
$subFont = New-Font 9

Fill-Gradient $g ([System.Drawing.Rectangle]::FromLTRB(0, 0, 1200, 675)) `
    ([System.Drawing.Color]::FromArgb(255, 22, 22, 28)) `
    ([System.Drawing.Color]::FromArgb(255, 10, 10, 14))

if (Test-Path $IconPath) {
    $icon = [System.Drawing.Image]::FromFile($IconPath)
    Draw-RoundedRect $g $null (New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 51, 51, 51))) 56 170 64 64 14
    $g.DrawImage($icon, 56, 170, 64, 64)
    $icon.Dispose()
}

$heroFont = New-Font 34 Bold
$emBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 78, 187, 228))
$g.DrawString("Animated", $heroFont, $white, 56, 250)
$g.DrawString("GIF", $heroFont, $emBrush, 230, 250)
$g.DrawString("on D6 Keys", $heroFont, $white, 56, 295)

$descFont = New-Font 12
$descRect = New-Object System.Drawing.RectangleF 56, 360, 420, 80
$g.DrawString("D6 GIF Keys for FIFINE D6 and StreamDock. Load a file or URL, tune speed 25-400%, fixed FPS or native GIF timing.", $descFont, $gray, $descRect)

$tags = @("GIF animation", "Speed control", "Counter", "Open URL")
$tx = 56
foreach ($t in $tags) {
    $tw = [int]$g.MeasureString($t, $subFont).Width + 24
    $tagBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(30, 78, 187, 228))
    $tagPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(90, 78, 187, 228))
    Draw-RoundedRect $g $tagBrush $tagPen $tx 430 $tw 28 14
    $g.DrawString($t, $subFont, $emBrush, ($tx + 12), 436)
    $tx += $tw + 10
}

$deckBrush2 = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 13, 13, 16))
Draw-RoundedRect $g $deckBrush2 (New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 42, 42, 50))) 620 200 260 190 16
$ks2 = 72; $g2x = 638; $g2y = 218
Draw-Key $g $g2x $g2y $ks2 $demoGif $defaultJpg "LIVE" $true
Draw-Key $g ($g2x + $ks2 + 8) $g2y $ks2 $demoGif $defaultJpg "" $true
$g.DrawString("42", (New-Font 18 Bold), $cntBrush, ($g2x + 2*($ks2+8) + 24), ($g2y + 22))
$g.DrawString("URL", $subFont, $gray, ($g2x + $ks2 + 8), ($g2y + 2*($ks2+8) + 28))

$panelBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 45, 45, 45))
Draw-RoundedRect $g $panelBrush (New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 58, 58, 58))) 900 160 280 360 8
$g.DrawLine($linePen, 916, 198, 980, 198)
$g.DrawString($heading, $headFont, $headBrush, 990, 188)
$g.DrawLine($linePen, 1080, 198, 1164, 198)

$py = 220
$simpleRows = @(@("Speed", "150%"), @("Timing", "Fixed FPS"), @("FPS", "15"), @("Background", "50%"), @("Title", "LIVE"))
foreach ($row in $simpleRows) {
    $g.DrawString($row[0], $labelFont, $labelBrush, 916, $py)
    $g.DrawString($row[1], $labelFont, $valueBrush, 1010, $py)
    $py += 32
}
$prev2 = [System.Drawing.Image]::FromFile($demoGif)
$g.DrawImage($prev2, 1010, 380, 80, 80)
$prev2.Dispose()

Save-Canvas $c "03-store-hero.png" | Out-Null

Write-Host "Screenshots saved to: $OutDir"
Get-ChildItem $OutDir -Filter *.png | ForEach-Object {
    $kb = [math]::Round($_.Length / 1024, 1)
    Write-Host ("  {0} ({1} KB)" -f $_.Name, $kb)
}
