# Renders store screenshots in 16:9 (1280x720).
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$W = 1280
$H = 720

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
        $font = New-Font ([Math]::Max(9, $size / 11)) Bold
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

function Draw-SettingsPanel($g, [int]$ox, [int]$oy) {
    $labelFont = New-Font 10
    $labelBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 154, 154, 154))
    $valueBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 216, 216, 216))
    $boxBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 61, 61, 61))
    $boxPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 150, 150, 150))
    $accent = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 78, 187, 228))

    $rows = @(
        @{ L = [string][char]0x0424 + [char]0x0430 + [char]0x0439 + [char]0x043B + " GIF"; V = "demo.gif"; Y = 56 },
        @{ L = [string][char]0x0438 + [char]0x043B + [char]0x0438 + " URL"; V = "https://example.com/cat.gif"; Y = 96 },
        @{ L = [string][char]0x0421 + [char]0x043A + [char]0x043E + [char]0x0440 + [char]0x043E + [char]0x0441 + [char]0x0442 + [char]0x044C + " (%)"; V = "150%"; Y = 136; Bar = 150 },
        @{ L = [string][char]0x0422 + [char]0x0430 + [char]0x0439 + [char]0x043C + [char]0x0438 + [char]0x043D + [char]0x0433; V = [string][char]0x0424 + [char]0x0438 + [char]0x043A + [char]0x0441 + [char]0x002E + " FPS"; Y = 176 },
        @{ L = "FPS (1-30)"; V = "15"; Y = 216 },
        @{ L = [string][char]0x0424 + [char]0x043E + [char]0x043D + " (%)"; V = "50%"; Y = 256; Bar = 125 },
        @{ L = [string][char]0x041F + [char]0x043E + [char]0x0434 + [char]0x043F + [char]0x0438 + [char]0x0441 + [char]0x044C; V = "LIVE"; Y = 296 }
    )

    foreach ($row in $rows) {
        $y = $oy + $row.Y
        $g.DrawString($row.L, $labelFont, $labelBrush, ($ox + 20), $y)
        if ($row.Bar) {
            $g.FillRectangle($boxBrush, ($ox + 120), ($y + 8), 250, 7)
            $g.FillRectangle($accent, ($ox + 120), ($y + 8), $row.Bar, 7)
            $g.DrawString($row.V, (New-Font 10 Bold), $accent, ($ox + 380), ($y + 2))
        } elseif ($row.L -like "*URL*") {
            Draw-RoundedRect $g $boxBrush $boxPen ($ox + 120) $y 320 26 0
            $g.DrawString($row.V, (New-Font 9), $valueBrush, ($ox + 126), ($y + 5))
        } else {
            Draw-RoundedRect $g $boxBrush $boxPen ($ox + 120) $y 200 26 0
            $g.DrawString($row.V, $labelFont, $valueBrush, ($ox + 128), ($y + 5))
        }
    }

    $prevLabel = [string][char]0x041F + [char]0x0440 + [char]0x0435 + [char]0x0432 + [char]0x044C + [char]0x044E
    $g.DrawString($prevLabel, $labelFont, $labelBrush, ($ox + 20), ($oy + 348))
    $prev = [System.Drawing.Image]::FromFile($demoGif)
    $g.DrawImage($prev, ($ox + 120), ($oy + 348), 140, 140)
    $prev.Dispose()
    $g.DrawRectangle($boxPen, ($ox + 120), ($oy + 348), 140, 140)
}

$heading = "GIF " + [char]0x043D + [char]0x0430 + [char]0x0020 + [char]0x043A + [char]0x043D + [char]0x043E + [char]0x043F + [char]0x043A + [char]0x0435

# --- 01 settings (16:9) ---
$c = New-Canvas $W $H
$g = $c.G
Fill-Gradient $g ([System.Drawing.Rectangle]::FromLTRB(0, 0, $W, $H)) `
    ([System.Drawing.Color]::FromArgb(255, 28, 28, 34)) `
    ([System.Drawing.Color]::FromArgb(255, 14, 14, 18))

$panelX = 100; $panelY = 70; $panelW = 460; $panelH = 580
$panelBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 45, 45, 45))
$panelPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 58, 58, 58))
Draw-RoundedRect $g $panelBrush $panelPen $panelX $panelY $panelW $panelH 10

$headFont = New-Font 12
$headBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 216, 216, 216))
$linePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 61, 61, 61))
$g.DrawLine($linePen, ($panelX + 20), ($panelY + 42), ($panelX + 130), ($panelY + 42))
$g.DrawString($heading, $headFont, $headBrush, ($panelX + 140), ($panelY + 30))
$g.DrawLine($linePen, ($panelX + 280), ($panelY + 42), ($panelX + $panelW - 20), ($panelY + 42))

Draw-SettingsPanel $g $panelX $panelY

$titleFont = New-Font 28 Bold
$subFont = New-Font 14
$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 232, 232, 245))
$gray = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 122, 122, 136))
$accent = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 78, 187, 228))
$g.DrawString("D6 GIF Keys", $titleFont, $white, 640, 120)
$g.DrawString("Settings panel", $subFont, $accent, 640, 168)
$g.DrawString("Speed, timing, background opacity", $subFont, $gray, 640, 200)

Draw-Key $g 700 280 160 $demoGif $defaultJpg "LIVE" $true
Draw-Key $g 880 280 160 $demoGif $defaultJpg "" $true

Save-Canvas $c "01-settings-panel.png" | Out-Null

# --- 02 d6 keys (16:9) ---
$c = New-Canvas $W $H
$g = $c.G
Fill-Gradient $g ([System.Drawing.Rectangle]::FromLTRB(0, 0, $W, $H)) `
    ([System.Drawing.Color]::FromArgb(255, 30, 30, 36)) `
    ([System.Drawing.Color]::FromArgb(255, 18, 18, 24))

$titleFont = New-Font 32 Bold
$subFont = New-Font 16
$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 232, 232, 245))
$gray = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 122, 122, 136))
$cntBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 204, 204, 204))

$g.DrawString("FIFINE AmpliGame D6", $titleFont, $white, 380, 80)
$sub = "GIF-" + [char]0x043A + [char]0x043B + [char]0x044E + [char]0x0447 + [char]0x0438 + " D6"
$g.DrawString($sub, $subFont, $gray, 500, 130)

$deckW = 520; $deckH = 360; $deckX = ($W - $deckW) / 2; $deckY = 200
$deckBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 13, 13, 16))
$deckPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 42, 42, 50))
Draw-RoundedRect $g $deckBrush $deckPen $deckX $deckY $deckW $deckH 18

$ks = 120; $gap = 16
$gridW = 3 * $ks + 2 * $gap
$gridH = 2 * $ks + $gap
$kx = $deckX + ($deckW - $gridW) / 2
$ky = $deckY + ($deckH - $gridH) / 2

Draw-Key $g $kx $ky $ks $demoGif $defaultJpg "LIVE" $true
Draw-Key $g ($kx + $ks + $gap) $ky $ks $demoGif $defaultJpg "" $true
$g.DrawString("42", (New-Font 32 Bold), $cntBrush, ($kx + 2*($ks+$gap) + 42), ($ky + 38))
Draw-Key $g $kx ($ky + $ks + $gap) $ks $null $null "" $false 0
Draw-Key $g ($kx + $ks + $gap) ($ky + $ks + $gap) $ks $null $null "" $false 0
$g.DrawString("URL", (New-Font 14), $gray, ($kx + 2*($ks+$gap) + 38), ($ky + $ks + $gap + 48))

$legendFont = New-Font 12
$accent = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 78, 187, 228))
$green = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 126, 217, 87))
$g.FillEllipse($accent, 520, 620, 10, 10)
$gifLbl = "GIF-" + [char]0x043A + [char]0x043D + [char]0x043E + [char]0x043F + [char]0x043A + [char]0x0430
$g.DrawString($gifLbl, $legendFont, $gray, 538, 614)
$g.FillEllipse($green, 660, 620, 10, 10)
$cntLbl = [char]0x0421 + [char]0x0447 + [char]0x0451 + [char]0x0442 + [char]0x0447 + [char]0x0438 + [char]0x043A
$g.DrawString($cntLbl, $legendFont, $gray, 678, 614)

Save-Canvas $c "02-d6-keys.png" | Out-Null

# --- 03 hero (16:9) ---
$c = New-Canvas $W $H
$g = $c.G
$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 232, 232, 245))
$gray = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 122, 122, 136))
$cntBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 204, 204, 204))
$labelFont = New-Font 10
$labelBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 154, 154, 154))
$valueBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 216, 216, 216))
$headFont = New-Font 11
$headBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 216, 216, 216))
$linePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 61, 61, 61))
$subFont = New-Font 11

Fill-Gradient $g ([System.Drawing.Rectangle]::FromLTRB(0, 0, $W, $H)) `
    ([System.Drawing.Color]::FromArgb(255, 22, 22, 28)) `
    ([System.Drawing.Color]::FromArgb(255, 10, 10, 14))

if (Test-Path $IconPath) {
    $icon = [System.Drawing.Image]::FromFile($IconPath)
    Draw-RoundedRect $g $null (New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 51, 51, 51))) 72 180 72 72 14
    $g.DrawImage($icon, 72, 180, 72, 72)
    $icon.Dispose()
}

$heroFont = New-Font 40 Bold
$emBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 78, 187, 228))
$g.DrawString("Animated", $heroFont, $white, 72, 270)
$g.DrawString("GIF", $heroFont, $emBrush, 280, 270)
$g.DrawString("on D6 Keys", $heroFont, $white, 72, 325)

$descFont = New-Font 14
$descRect = New-Object System.Drawing.RectangleF 72, 395, 480, 90
$g.DrawString("D6 GIF Keys for FIFINE D6 and StreamDock. Load a file or URL, tune speed 25-400%, fixed FPS or native GIF timing.", $descFont, $gray, $descRect)

$tags = @("GIF animation", "Speed control", "Counter", "Open URL")
$tx = 72
foreach ($t in $tags) {
    $tw = [int]$g.MeasureString($t, $subFont).Width + 28
    $tagBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(30, 78, 187, 228))
    $tagPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(90, 78, 187, 228))
    Draw-RoundedRect $g $tagBrush $tagPen $tx 510 $tw 32 14
    $g.DrawString($t, $subFont, $emBrush, ($tx + 14), 517)
    $tx += $tw + 12
}

$deckBrush2 = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 13, 13, 16))
Draw-RoundedRect $g $deckBrush2 (New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 42, 42, 50))) 620 200 300 220 16
$ks2 = 88; $g2x = 648; $g2y = 230
Draw-Key $g $g2x $g2y $ks2 $demoGif $defaultJpg "LIVE" $true
Draw-Key $g ($g2x + $ks2 + 12) $g2y $ks2 $demoGif $defaultJpg "" $true
$g.DrawString("42", (New-Font 22 Bold), $cntBrush, ($g2x + 2*($ks2+12) + 30), ($g2y + 28))
$g.DrawString("URL", $subFont, $gray, ($g2x + $ks2 + 12), ($g2y + 2*($ks2+12) + 34))

$panelBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 45, 45, 45))
Draw-RoundedRect $g $panelBrush (New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 58, 58, 58))) 960 160 300 400 10
$g.DrawLine($linePen, 978, 200, 1048, 200)
$g.DrawString($heading, $headFont, $headBrush, 1058, 190)
$g.DrawLine($linePen, 1160, 200, 1240, 200)

$py = 230
$simpleRows = @(@("Speed", "150%"), @("Timing", "Fixed FPS"), @("FPS", "15"), @("Background", "50%"), @("Title", "LIVE"))
foreach ($row in $simpleRows) {
    $g.DrawString($row[0], $labelFont, $labelBrush, 978, $py)
    $g.DrawString($row[1], $labelFont, $valueBrush, 1080, $py)
    $py += 36
}
$prev2 = [System.Drawing.Image]::FromFile($demoGif)
$g.DrawImage($prev2, 1080, 420, 100, 100)
$prev2.Dispose()

Save-Canvas $c "03-store-hero.png" | Out-Null

Write-Host "Screenshots saved to: $OutDir (16:9 ${W}x${H})"
Get-ChildItem $OutDir -Filter *.png | ForEach-Object {
    $img = [System.Drawing.Image]::FromFile($_.FullName)
    $ratio = "{0}:{1}" -f $img.Width, $img.Height
    $img.Dispose()
    $kb = [math]::Round($_.Length / 1024, 1)
    Write-Host ("  {0}  {1}  ({2} KB)" -f $_.Name, $ratio, $kb)
}
