$ErrorActionPreference = "Stop"

Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName PresentationFramework

$width = 1200
$height = 300
$frameCount = 18
$frameDelayCs = 10

$repoRoot = Split-Path -Parent $PSScriptRoot
$gifPath = Join-Path $repoRoot "assets\banner.gif"
$previewPath = Join-Path $repoRoot "assets\banner-preview.png"

$titleTypeface = [System.Windows.Media.Typeface]::new(
  [System.Windows.Media.FontFamily]::new("Segoe UI"),
  [System.Windows.FontStyles]::Normal,
  [System.Windows.FontWeights]::Bold,
  [System.Windows.FontStretches]::Normal
)

$subtitleTypeface = [System.Windows.Media.Typeface]::new(
  [System.Windows.Media.FontFamily]::new("Segoe UI"),
  [System.Windows.FontStyles]::Normal,
  [System.Windows.FontWeights]::SemiBold,
  [System.Windows.FontStretches]::Normal
)

$dpi = 96.0
$pixelsPerDip = 1.0

function New-Brush {
  param(
    [string]$Color,
    [double]$Opacity = 1.0
  )

  $base = [System.Windows.Media.ColorConverter]::ConvertFromString($Color)
  [System.Windows.Media.SolidColorBrush]::new(
    [System.Windows.Media.Color]::FromArgb(
      [byte][Math]::Round(255 * $Opacity),
      $base.R,
      $base.G,
      $base.B
    )
  )
}

function New-FormattedText {
  param(
    [string]$Text,
    [System.Windows.Media.Typeface]$Typeface,
    [double]$Size,
    [System.Windows.Media.Brush]$Brush
  )

  [System.Windows.Media.FormattedText]::new(
    $Text,
    [System.Globalization.CultureInfo]::InvariantCulture,
    [System.Windows.FlowDirection]::LeftToRight,
    $Typeface,
    $Size,
    $Brush,
    $pixelsPerDip
  )
}

function New-WaveFillGeometry {
  param(
    [double]$StartY,
    [double]$Control1Y,
    [double]$Control2Y,
    [double]$MidY,
    [double]$Control3Y,
    [double]$Control4Y,
    [double]$EndY
  )

  $figure = [System.Windows.Media.PathFigure]::new()
  $figure.StartPoint = [System.Windows.Point]::new(0, $StartY)
  $figure.IsClosed = $true
  $figure.Segments.Add([System.Windows.Media.BezierSegment]::new(
    [System.Windows.Point]::new(150, $Control1Y),
    [System.Windows.Point]::new(360, $Control2Y),
    [System.Windows.Point]::new(600, $MidY),
    $true
  ))
  $figure.Segments.Add([System.Windows.Media.BezierSegment]::new(
    [System.Windows.Point]::new(840, $Control3Y),
    [System.Windows.Point]::new(1040, $Control4Y),
    [System.Windows.Point]::new($width, $EndY),
    $true
  ))
  $figure.Segments.Add([System.Windows.Media.LineSegment]::new([System.Windows.Point]::new($width, $height), $true))
  $figure.Segments.Add([System.Windows.Media.LineSegment]::new([System.Windows.Point]::new(0, $height), $true))

  $geometry = [System.Windows.Media.PathGeometry]::new()
  $geometry.Figures.Add($figure)
  $geometry
}

function New-WaveStrokeGeometry {
  param(
    [double]$StartY,
    [double]$Control1Y,
    [double]$Control2Y,
    [double]$MidY,
    [double]$Control3Y,
    [double]$Control4Y,
    [double]$EndY
  )

  $figure = [System.Windows.Media.PathFigure]::new()
  $figure.StartPoint = [System.Windows.Point]::new(0, $StartY)
  $figure.IsClosed = $false
  $figure.Segments.Add([System.Windows.Media.BezierSegment]::new(
    [System.Windows.Point]::new(170, $Control1Y),
    [System.Windows.Point]::new(380, $Control2Y),
    [System.Windows.Point]::new(610, $MidY),
    $true
  ))
  $figure.Segments.Add([System.Windows.Media.BezierSegment]::new(
    [System.Windows.Point]::new(820, $Control3Y),
    [System.Windows.Point]::new(1020, $Control4Y),
    [System.Windows.Point]::new($width, $EndY),
    $true
  ))

  $geometry = [System.Windows.Media.PathGeometry]::new()
  $geometry.Figures.Add($figure)
  $geometry
}

function Draw-TextBlock {
  param(
    [System.Windows.Media.DrawingContext]$Context
  )

  $titleText = "Reet Ginotra"
  $subtitleText = "Full Stack Developer | AI | Product"

  $titleMeasure = New-FormattedText -Text $titleText -Typeface $titleTypeface -Size 52 -Brush (New-Brush -Color "#FFFFFF")
  $subtitleMeasure = New-FormattedText -Text $subtitleText -Typeface $subtitleTypeface -Size 20 -Brush (New-Brush -Color "#FFFFFF")

  $titleX = ($width - $titleMeasure.Width) / 2
  $titleY = 92
  $subtitleX = ($width - $subtitleMeasure.Width) / 2
  $subtitleY = 154

  $shadowBrush = New-Brush -Color "#0F1238" -Opacity 0.28
  $titleShadow = New-FormattedText -Text $titleText -Typeface $titleTypeface -Size 52 -Brush $shadowBrush
  $subtitleShadow = New-FormattedText -Text $subtitleText -Typeface $subtitleTypeface -Size 20 -Brush $shadowBrush

  $Context.DrawText($titleShadow, [System.Windows.Point]::new($titleX, $titleY + 2))
  $Context.DrawText($subtitleShadow, [System.Windows.Point]::new($subtitleX, $subtitleY + 1.5))
  $Context.DrawText($titleMeasure, [System.Windows.Point]::new($titleX, $titleY))
  $Context.DrawText($subtitleMeasure, [System.Windows.Point]::new($subtitleX, $subtitleY))
}

$frames = [System.Collections.Generic.List[System.Windows.Media.Imaging.BitmapFrame]]::new()

for ($frameIndex = 0; $frameIndex -lt $frameCount; $frameIndex++) {
  $phase = ($frameIndex / $frameCount) * [Math]::PI * 2.0

  $visual = [System.Windows.Media.DrawingVisual]::new()
  $context = $visual.RenderOpen()

  $background = [System.Windows.Media.LinearGradientBrush]::new()
  $background.StartPoint = [System.Windows.Point]::new(0, 0)
  $background.EndPoint = [System.Windows.Point]::new(1, 0)
  $background.GradientStops.Add([System.Windows.Media.GradientStop]::new(([System.Windows.Media.ColorConverter]::ConvertFromString("#3F63B7")), 0.0))
  $background.GradientStops.Add([System.Windows.Media.GradientStop]::new(([System.Windows.Media.ColorConverter]::ConvertFromString("#6B45AD")), 1.0))
  $context.DrawRectangle($background, $null, [System.Windows.Rect]::new(0, 0, $width, $height))

  $baseWave = New-WaveFillGeometry `
    -StartY (270 + [Math]::Sin($phase) * 3) `
    -Control1Y (224 + [Math]::Cos($phase * 0.9) * 4) `
    -Control2Y (234 + [Math]::Sin($phase * 0.8) * 4) `
    -MidY (282 + [Math]::Cos($phase) * 4) `
    -Control3Y (292 + [Math]::Sin($phase * 0.75) * 3) `
    -Control4Y (238 + [Math]::Cos($phase * 0.9) * 4) `
    -EndY (248 + [Math]::Sin($phase) * 3)
  $context.DrawGeometry((New-Brush -Color "#2C2C67" -Opacity 0.92), $null, $baseWave)

  $midWave = New-WaveFillGeometry `
    -StartY (248 + [Math]::Cos($phase * 0.85) * 3) `
    -Control1Y (202 + [Math]::Sin($phase * 0.9) * 4) `
    -Control2Y (212 + [Math]::Cos($phase * 0.8) * 3) `
    -MidY (258 + [Math]::Sin($phase) * 3) `
    -Control3Y (270 + [Math]::Cos($phase * 0.75) * 3) `
    -Control4Y (218 + [Math]::Sin($phase * 0.9) * 4) `
    -EndY (228 + [Math]::Cos($phase * 0.85) * 3)
  $context.DrawGeometry((New-Brush -Color "#4D438A" -Opacity 0.82), $null, $midWave)

  $frontWave = New-WaveFillGeometry `
    -StartY (228 + [Math]::Sin($phase * 0.8) * 2.5) `
    -Control1Y (192 + [Math]::Cos($phase * 0.95) * 3) `
    -Control2Y (202 + [Math]::Sin($phase * 0.9) * 2.5) `
    -MidY (244 + [Math]::Cos($phase) * 2.5) `
    -Control3Y (256 + [Math]::Sin($phase * 0.8) * 2.5) `
    -Control4Y (208 + [Math]::Cos($phase * 0.95) * 3) `
    -EndY (218 + [Math]::Sin($phase * 0.8) * 2.5)
  $context.DrawGeometry((New-Brush -Color "#5E5CB0" -Opacity 0.55), $null, $frontWave)

  $lineOne = New-WaveStrokeGeometry `
    -StartY (202 + [Math]::Sin($phase * 0.9) * 2) `
    -Control1Y (176 + [Math]::Cos($phase) * 2.5) `
    -Control2Y (186 + [Math]::Sin($phase * 0.8) * 2.5) `
    -MidY (226 + [Math]::Cos($phase * 0.85) * 2.2) `
    -Control3Y (236 + [Math]::Sin($phase * 0.9) * 2) `
    -Control4Y (192 + [Math]::Cos($phase) * 2.5) `
    -EndY (204 + [Math]::Sin($phase * 0.9) * 2)
  $lineOnePen = [System.Windows.Media.Pen]::new((New-Brush -Color "#FFFFFF" -Opacity 0.95), 4.2)
  $lineOnePen.StartLineCap = [System.Windows.Media.PenLineCap]::Round
  $lineOnePen.EndLineCap = [System.Windows.Media.PenLineCap]::Round
  $lineOnePen.LineJoin = [System.Windows.Media.PenLineJoin]::Round
  $context.DrawGeometry($null, $lineOnePen, $lineOne)

  $lineTwo = New-WaveStrokeGeometry `
    -StartY (194 + [Math]::Cos($phase * 0.75) * 1.8) `
    -Control1Y (182 + [Math]::Sin($phase * 0.85) * 2.2) `
    -Control2Y (174 + [Math]::Cos($phase) * 2.0) `
    -MidY (216 + [Math]::Sin($phase * 0.75) * 1.8) `
    -Control3Y (226 + [Math]::Cos($phase * 0.85) * 2.2) `
    -Control4Y (184 + [Math]::Sin($phase) * 2.0) `
    -EndY (196 + [Math]::Cos($phase * 0.75) * 1.8)
  $lineTwoPen = [System.Windows.Media.Pen]::new((New-Brush -Color "#D7FFFA" -Opacity 0.78), 2.0)
  $lineTwoPen.StartLineCap = [System.Windows.Media.PenLineCap]::Round
  $lineTwoPen.EndLineCap = [System.Windows.Media.PenLineCap]::Round
  $lineTwoPen.LineJoin = [System.Windows.Media.PenLineJoin]::Round
  $context.DrawGeometry($null, $lineTwoPen, $lineTwo)

  Draw-TextBlock -Context $context
  $context.Close()

  $bitmap = [System.Windows.Media.Imaging.RenderTargetBitmap]::new($width, $height, $dpi, $dpi, [System.Windows.Media.PixelFormats]::Pbgra32)
  $bitmap.Render($visual)

  if ($frameIndex -eq 0) {
    $pngEncoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
    $pngEncoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
    $pngStream = [System.IO.File]::Open($previewPath, [System.IO.FileMode]::Create)
    try {
      $pngEncoder.Save($pngStream)
    } finally {
      $pngStream.Dispose()
    }
  }

  $metadata = [System.Windows.Media.Imaging.BitmapMetadata]::new("gif")
  $metadata.SetQuery("/grctlext/Delay", [System.UInt16]$frameDelayCs)
  $metadata.SetQuery("/grctlext/Disposal", [System.Byte]2)
  $frame = [System.Windows.Media.Imaging.BitmapFrame]::Create($bitmap, $null, $metadata, $null)
  $frames.Add($frame)
}

$gifEncoder = [System.Windows.Media.Imaging.GifBitmapEncoder]::new()
foreach ($frame in $frames) {
  $gifEncoder.Frames.Add($frame)
}

$gifStream = [System.IO.File]::Open($gifPath, [System.IO.FileMode]::Create)
try {
  $gifEncoder.Save($gifStream)
} finally {
  $gifStream.Dispose()
}

$gifBytes = [System.IO.File]::ReadAllBytes($gifPath)
$packedField = $gifBytes[10]
$hasGlobalColorTable = ($packedField -band 0x80) -ne 0
$gctSize = 0
if ($hasGlobalColorTable) {
  $sizeBits = $packedField -band 0x07
  $gctSize = 3 * [Math]::Pow(2, $sizeBits + 1)
}

$insertIndex = 13 + [int]$gctSize
$loopExtension = [byte[]](
  0x21, 0xFF, 0x0B,
  0x4E, 0x45, 0x54, 0x53, 0x43, 0x41, 0x50, 0x45, 0x32, 0x2E, 0x30,
  0x03, 0x01, 0x00, 0x00, 0x00
)
$combined = [byte[]]::new($gifBytes.Length + $loopExtension.Length)
[Array]::Copy($gifBytes, 0, $combined, 0, $insertIndex)
[Array]::Copy($loopExtension, 0, $combined, $insertIndex, $loopExtension.Length)
[Array]::Copy($gifBytes, $insertIndex, $combined, $insertIndex + $loopExtension.Length, $gifBytes.Length - $insertIndex)
[System.IO.File]::WriteAllBytes($gifPath, $combined)
