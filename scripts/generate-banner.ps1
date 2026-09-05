$ErrorActionPreference = "Stop"

Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName PresentationFramework

$width = 1200
$height = 300
$frameCount = 24
$frameDelayCs = 8

$repoRoot = Split-Path -Parent $PSScriptRoot
$outputGif = Join-Path $repoRoot "assets\banner.gif"
$outputPreview = Join-Path $repoRoot "assets\banner-preview.png"

$fontCandidates = @(
  "C:\Windows\Fonts\segoeuib.ttf",
  "C:\Windows\Fonts\arialbd.ttf",
  "C:\Windows\Fonts\arial.ttf"
)

$fontPath = $fontCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $fontPath) {
  throw "Could not find a usable system font."
}

$fontUri = [Uri]("file:///" + ($fontPath -replace "\\","/"))
$fontFamily = [System.Windows.Media.FontFamily]::new($fontUri, "./#Segoe UI")
if (-not $fontFamily) {
  $fontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
}

$titleTypeface = [System.Windows.Media.Typeface]::new(
  $fontFamily,
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

function New-FormattedText {
  param(
    [string]$Text,
    [System.Windows.Media.Typeface]$Typeface,
    [double]$Size,
    [System.Windows.Media.Brush]$Brush
  )

  return [System.Windows.Media.FormattedText]::new(
    $Text,
    [System.Globalization.CultureInfo]::InvariantCulture,
    [System.Windows.FlowDirection]::LeftToRight,
    $Typeface,
    $Size,
    $Brush,
    $pixelsPerDip
  )
}

function New-GradientBrush {
  $brush = [System.Windows.Media.LinearGradientBrush]::new()
  $brush.StartPoint = [System.Windows.Point]::new(0, 0)
  $brush.EndPoint = [System.Windows.Point]::new(1, 1)
  $brush.GradientStops.Add([System.Windows.Media.GradientStop]::new(([System.Windows.Media.ColorConverter]::ConvertFromString("#0f172a")), 0.0))
  $brush.GradientStops.Add([System.Windows.Media.GradientStop]::new(([System.Windows.Media.ColorConverter]::ConvertFromString("#1e1b4b")), 0.52))
  $brush.GradientStops.Add([System.Windows.Media.GradientStop]::new(([System.Windows.Media.ColorConverter]::ConvertFromString("#311042")), 1.0))
  return $brush
}

function New-StrandGeometry {
  param(
    [double]$BaseY,
    [double]$Amplitude,
    [double]$Phase,
    [double]$Twist,
    [double]$Sag,
    [double]$LeftInset,
    [double]$RightInset
  )

  $startX = 140 + $LeftInset
  $endX = 1060 - $RightInset
  $centerX = 600

  $p0 = [System.Windows.Point]::new($startX, $BaseY + [Math]::Sin($Phase) * $Amplitude * 0.42)
  $p1 = [System.Windows.Point]::new(
    $startX + 150,
    $BaseY - $Amplitude + [Math]::Cos($Phase * 1.17 + $Twist) * $Amplitude * 0.35
  )
  $p2 = [System.Windows.Point]::new(
    $centerX - 130,
    $BaseY + $Sag + [Math]::Sin($Phase * 1.31 + $Twist) * $Amplitude * 0.28
  )
  $p3 = [System.Windows.Point]::new(
    $centerX,
    $BaseY + [Math]::Cos($Phase * 1.08 - $Twist) * $Amplitude * 0.18
  )
  $p4 = [System.Windows.Point]::new(
    $centerX + 140,
    $BaseY - $Sag + [Math]::Sin($Phase * 1.22 - $Twist) * $Amplitude * 0.24
  )
  $p5 = [System.Windows.Point]::new(
    $endX - 170,
    $BaseY + $Amplitude + [Math]::Cos($Phase * 0.94 + $Twist) * $Amplitude * 0.30
  )
  $p6 = [System.Windows.Point]::new(
    $endX,
    $BaseY + [Math]::Sin($Phase * 0.88) * $Amplitude * 0.38
  )

  $figure = [System.Windows.Media.PathFigure]::new()
  $figure.StartPoint = $p0
  $figure.IsClosed = $false
  $figure.Segments.Add([System.Windows.Media.BezierSegment]::new($p1, $p2, $p3, $true))
  $figure.Segments.Add([System.Windows.Media.BezierSegment]::new($p4, $p5, $p6, $true))

  $geometry = [System.Windows.Media.PathGeometry]::new()
  $geometry.Figures.Add($figure)
  return $geometry
}

$strandSpecs = @(
  @{ BaseY = 92;  Amplitude = 16; Twist = 0.2;  Sag = 8;  LeftInset = 0;  RightInset = 0;  Color = "#67E8F9"; Width = 1.8; Opacity = 0.75 },
  @{ BaseY = 104; Amplitude = 14; Twist = 0.7;  Sag = 10; LeftInset = 18; RightInset = 14; Color = "#38BDF8"; Width = 1.5; Opacity = 0.60 },
  @{ BaseY = 116; Amplitude = 18; Twist = 1.3;  Sag = 12; LeftInset = 4;  RightInset = 26; Color = "#2DD4BF"; Width = 1.7; Opacity = 0.68 },
  @{ BaseY = 128; Amplitude = 13; Twist = 2.1;  Sag = 9;  LeftInset = 24; RightInset = 6;  Color = "#5EEAD4"; Width = 1.35; Opacity = 0.54 },
  @{ BaseY = 138; Amplitude = 17; Twist = 2.6;  Sag = 11; LeftInset = 0;  RightInset = 0;  Color = "#60A5FA"; Width = 1.6; Opacity = 0.58 },
  @{ BaseY = 150; Amplitude = 15; Twist = 3.0;  Sag = 10; LeftInset = 12; RightInset = 18; Color = "#22D3EE"; Width = 1.45; Opacity = 0.57 },
  @{ BaseY = 162; Amplitude = 18; Twist = 3.5;  Sag = 13; LeftInset = 28; RightInset = 10; Color = "#34D399"; Width = 1.5; Opacity = 0.55 },
  @{ BaseY = 174; Amplitude = 14; Twist = 4.1;  Sag = 12; LeftInset = 6;  RightInset = 22; Color = "#67E8F9"; Width = 1.3; Opacity = 0.50 },
  @{ BaseY = 186; Amplitude = 16; Twist = 4.6;  Sag = 10; LeftInset = 20; RightInset = 2;  Color = "#38BDF8"; Width = 1.25; Opacity = 0.46 },
  @{ BaseY = 198; Amplitude = 12; Twist = 5.2;  Sag = 8;  LeftInset = 34; RightInset = 34; Color = "#2DD4BF"; Width = 1.15; Opacity = 0.42 }
)

$frames = [System.Collections.Generic.List[System.Windows.Media.Imaging.BitmapFrame]]::new()
$gradientBrush = New-GradientBrush

for ($frameIndex = 0; $frameIndex -lt $frameCount; $frameIndex++) {
  $progress = $frameIndex / $frameCount
  $phase = $progress * [Math]::PI * 2.0

  $visual = [System.Windows.Media.DrawingVisual]::new()
  $dc = $visual.RenderOpen()

  $dc.DrawRoundedRectangle($gradientBrush, $null, [System.Windows.Rect]::new(0, 0, $width, $height), 16, 16)

  foreach ($spec in $strandSpecs) {
    $geometry = New-StrandGeometry `
      -BaseY $spec.BaseY `
      -Amplitude $spec.Amplitude `
      -Phase ($phase + $spec.Twist) `
      -Twist $spec.Twist `
      -Sag $spec.Sag `
      -LeftInset $spec.LeftInset `
      -RightInset $spec.RightInset

    $baseColor = [System.Windows.Media.ColorConverter]::ConvertFromString($spec.Color)

    $glowPen = [System.Windows.Media.Pen]::new(
      [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb([byte](55 * $spec.Opacity), $baseColor.R, $baseColor.G, $baseColor.B)),
      $spec.Width + 3.2
    )
    $glowPen.StartLineCap = [System.Windows.Media.PenLineCap]::Round
    $glowPen.EndLineCap = [System.Windows.Media.PenLineCap]::Round
    $glowPen.LineJoin = [System.Windows.Media.PenLineJoin]::Round
    $dc.DrawGeometry($null, $glowPen, $geometry)

    $pen = [System.Windows.Media.Pen]::new(
      [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb([byte](255 * $spec.Opacity), $baseColor.R, $baseColor.G, $baseColor.B)),
      $spec.Width
    )
    $pen.StartLineCap = [System.Windows.Media.PenLineCap]::Round
    $pen.EndLineCap = [System.Windows.Media.PenLineCap]::Round
    $pen.LineJoin = [System.Windows.Media.PenLineJoin]::Round
    $dc.DrawGeometry($null, $pen, $geometry)
  }

  $titleText = New-FormattedText -Text "Reet Ginotra" -Typeface $titleTypeface -Size 56 -Brush ([System.Windows.Media.Brushes]::White)
  $subtitleText = New-FormattedText -Text "Full Stack Developer | AI | Product" -Typeface $subtitleTypeface -Size 21 -Brush ([System.Windows.Media.SolidColorBrush]::new(([System.Windows.Media.ColorConverter]::ConvertFromString("#DBEAFE"))))

  $titleOrigin = [System.Windows.Point]::new(($width - $titleText.Width) / 2, 98)
  $subtitleOrigin = [System.Windows.Point]::new(($width - $subtitleText.Width) / 2, 162)

  $dc.DrawText($titleText, $titleOrigin)
  $dc.DrawText($subtitleText, $subtitleOrigin)
  $dc.Close()

  $bitmap = [System.Windows.Media.Imaging.RenderTargetBitmap]::new($width, $height, $dpi, $dpi, [System.Windows.Media.PixelFormats]::Pbgra32)
  $bitmap.Render($visual)

  if ($frameIndex -eq 0) {
    $pngEncoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
    $pngEncoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
    $pngStream = [System.IO.File]::Open($outputPreview, [System.IO.FileMode]::Create)
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

$gifStream = [System.IO.File]::Open($outputGif, [System.IO.FileMode]::Create)
try {
  $gifEncoder.Save($gifStream)
} finally {
  $gifStream.Dispose()
}

$gifBytes = [System.IO.File]::ReadAllBytes($outputGif)
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
[System.IO.File]::WriteAllBytes($outputGif, $combined)
