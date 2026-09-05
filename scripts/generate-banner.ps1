$ErrorActionPreference = "Stop"

Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName PresentationFramework

$width = 1200
$height = 300
$frameCount = 28
$frameDelayCs = 9

$repoRoot = Split-Path -Parent $PSScriptRoot
$outputs = @(
  @{
    Name = "dark"
    GifPath = Join-Path $repoRoot "assets\banner-dark.gif"
    PreviewPath = Join-Path $repoRoot "assets\banner-dark-preview.png"
    PreviewBackground = "#0D1117"
    TitleFill = "#F8FBFF"
    TitleOutline = "#08111F"
    TitleOutlineWidth = 1.2
    TitleShadow = "#08111F"
    TitleShadowOpacity = 0.28
    TitleShadowX = 0.0
    TitleShadowY = 2.0
    SubtitleFill = "#D5E7FF"
    SubtitleOutline = "#08111F"
    SubtitleOutlineWidth = 0.8
    SubtitleShadow = "#08111F"
    SubtitleShadowOpacity = 0.18
    SubtitleShadowX = 0.0
    SubtitleShadowY = 1.2
  },
  @{
    Name = "light"
    GifPath = Join-Path $repoRoot "assets\banner-light.gif"
    PreviewPath = Join-Path $repoRoot "assets\banner-light-preview.png"
    PreviewBackground = "#FFFFFF"
    TitleFill = "#102841"
    TitleOutline = "#F7FCFF"
    TitleOutlineWidth = 0.9
    TitleShadow = "#BAE6FD"
    TitleShadowOpacity = 0.22
    TitleShadowX = 0.0
    TitleShadowY = 1.8
    SubtitleFill = "#25506E"
    SubtitleOutline = "#F8FBFF"
    SubtitleOutlineWidth = 0.35
    SubtitleShadow = "#E7F4FF"
    SubtitleShadowOpacity = 0.28
    SubtitleShadowX = 0.0
    SubtitleShadowY = 1.0
  }
)

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
$titleFamily = [System.Windows.Media.FontFamily]::new($fontUri, "./#Segoe UI")
if (-not $titleFamily) {
  $titleFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
}

$titleTypeface = [System.Windows.Media.Typeface]::new(
  $titleFamily,
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

function New-ColorBrush {
  param(
    [string]$Color,
    [double]$Opacity = 1.0
  )

  $base = [System.Windows.Media.ColorConverter]::ConvertFromString($Color)
  return [System.Windows.Media.SolidColorBrush]::new(
    [System.Windows.Media.Color]::FromArgb(
      [System.Byte][Math]::Round(255 * $Opacity),
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

function New-StrandGeometry {
  param(
    [hashtable]$Spec,
    [double]$Phase
  )

  $centerX = 600
  $waveA = [Math]::Sin($Phase * $Spec.SpeedA + $Spec.PhaseA)
  $waveB = [Math]::Cos($Phase * $Spec.SpeedB + $Spec.PhaseB)
  $waveC = [Math]::Sin($Phase * $Spec.SpeedC + $Spec.PhaseC)
  $waveD = [Math]::Cos($Phase * $Spec.SpeedD + $Spec.PhaseD)

  $p0 = [System.Windows.Point]::new($Spec.StartX + $waveB * $Spec.XDrift0, $Spec.Y0 + $waveA * $Spec.Swing0)
  $p1 = [System.Windows.Point]::new($Spec.C1X + $waveC * $Spec.XDrift1, $Spec.C1Y + $waveB * $Spec.Swing1)
  $p2 = [System.Windows.Point]::new($centerX - $Spec.C2Offset + $waveD * $Spec.XDrift2, $Spec.C2Y + $waveC * $Spec.Swing2)
  $p3 = [System.Windows.Point]::new($centerX + $Spec.CenterBias + $waveA * $Spec.XDrift3, $Spec.CenterY + $waveA * $Spec.CenterSwing - $waveB * $Spec.CenterLift)
  $p4 = [System.Windows.Point]::new($centerX + $Spec.C3Offset + $waveD * $Spec.XDrift4, $Spec.C3Y + $waveC * $Spec.Swing3)
  $p5 = [System.Windows.Point]::new($Spec.C4X + $waveA * $Spec.XDrift5, $Spec.C4Y + $waveB * $Spec.Swing4)
  $p6 = [System.Windows.Point]::new($Spec.EndX + $waveC * $Spec.XDrift6, $Spec.Y6 + $waveD * $Spec.Swing5)

  $figure = [System.Windows.Media.PathFigure]::new()
  $figure.StartPoint = $p0
  $figure.IsClosed = $false
  $figure.Segments.Add([System.Windows.Media.BezierSegment]::new($p1, $p2, $p3, $true))
  $figure.Segments.Add([System.Windows.Media.BezierSegment]::new($p4, $p5, $p6, $true))

  $geometry = [System.Windows.Media.PathGeometry]::new()
  $geometry.Figures.Add($figure)
  return $geometry
}

function Draw-TextGeometry {
  param(
    [System.Windows.Media.DrawingContext]$Context,
    [string]$Text,
    [System.Windows.Media.Typeface]$Typeface,
    [double]$Size,
    [string]$FillColor,
    [string]$OutlineColor,
    [double]$OutlineWidth,
    [string]$ShadowColor,
    [double]$ShadowOpacity,
    [double]$ShadowX,
    [double]$ShadowY,
    [double]$X,
    [double]$Y
  )

  $measureBrush = New-ColorBrush -Color $FillColor
  $formatted = New-FormattedText -Text $Text -Typeface $Typeface -Size $Size -Brush $measureBrush
  $mainGeometry = $formatted.BuildGeometry([System.Windows.Point]::new($X, $Y))
  $fillBrush = New-ColorBrush -Color $FillColor

  if ($ShadowOpacity -gt 0) {
    $shadowGeometry = $formatted.BuildGeometry([System.Windows.Point]::new($X + $ShadowX, $Y + $ShadowY))
    $Context.DrawGeometry((New-ColorBrush -Color $ShadowColor -Opacity $ShadowOpacity), $null, $shadowGeometry)
  }

  $outlinePen = $null
  if ($OutlineWidth -gt 0) {
    $outlinePen = [System.Windows.Media.Pen]::new((New-ColorBrush -Color $OutlineColor), $OutlineWidth)
    $outlinePen.LineJoin = [System.Windows.Media.PenLineJoin]::Round
  }

  $Context.DrawGeometry($fillBrush, $outlinePen, $mainGeometry)
}

$strandSpecs = @(
  @{
    StartX = 145; EndX = 1042; Y0 = 112; C1X = 270; C1Y = 66; C2Offset = 176; C2Y = 158; CenterY = 126; CenterBias = -12; C3Offset = 138; C3Y = 82; C4X = 938; C4Y = 72; Y6 = 108
    Swing0 = 7; Swing1 = 10; Swing2 = 11; Swing3 = 9; Swing4 = 10; Swing5 = 7; CenterSwing = 9; CenterLift = 5
    XDrift0 = 8; XDrift1 = 14; XDrift2 = 12; XDrift3 = 10; XDrift4 = 12; XDrift5 = 10; XDrift6 = 6
    SpeedA = 1.06; SpeedB = 0.84; SpeedC = 1.16; SpeedD = 0.92; PhaseA = 0.10; PhaseB = 1.30; PhaseC = 2.00; PhaseD = 0.50
    DarkColor = "#67E8F9"; LightColor = "#0891B2"; Width = 1.9; DarkGlow = 26; LightGlow = 18; DarkOpacity = 0.86; LightOpacity = 0.82
  },
  @{
    StartX = 165; EndX = 1028; Y0 = 140; C1X = 306; C1Y = 102; C2Offset = 190; C2Y = 186; CenterY = 150; CenterBias = 16; C3Offset = 154; C3Y = 112; C4X = 900; C4Y = 124; Y6 = 156
    Swing0 = 6; Swing1 = 9; Swing2 = 12; Swing3 = 8; Swing4 = 8; Swing5 = 6; CenterSwing = 10; CenterLift = 6
    XDrift0 = 6; XDrift1 = 10; XDrift2 = 12; XDrift3 = 14; XDrift4 = 11; XDrift5 = 8; XDrift6 = 5
    SpeedA = 0.92; SpeedB = 1.12; SpeedC = 0.96; SpeedD = 1.06; PhaseA = 1.10; PhaseB = 2.50; PhaseC = 0.90; PhaseD = 1.60
    DarkColor = "#38BDF8"; LightColor = "#0284C7"; Width = 1.55; DarkGlow = 22; LightGlow = 16; DarkOpacity = 0.70; LightOpacity = 0.74
  },
  @{
    StartX = 196; EndX = 1048; Y0 = 92; C1X = 342; C1Y = 148; C2Offset = 144; C2Y = 84; CenterY = 120; CenterBias = 24; C3Offset = 176; C3Y = 162; C4X = 924; C4Y = 100; Y6 = 88
    Swing0 = 5; Swing1 = 10; Swing2 = 8; Swing3 = 11; Swing4 = 7; Swing5 = 5; CenterSwing = 8; CenterLift = 4
    XDrift0 = 7; XDrift1 = 12; XDrift2 = 10; XDrift3 = 12; XDrift4 = 14; XDrift5 = 8; XDrift6 = 7
    SpeedA = 1.14; SpeedB = 0.88; SpeedC = 1.08; SpeedD = 0.98; PhaseA = 2.10; PhaseB = 0.60; PhaseC = 3.10; PhaseD = 2.60
    DarkColor = "#2DD4BF"; LightColor = "#0F766E"; Width = 1.62; DarkGlow = 20; LightGlow = 15; DarkOpacity = 0.68; LightOpacity = 0.72
  },
  @{
    StartX = 184; EndX = 1014; Y0 = 170; C1X = 320; C1Y = 116; C2Offset = 122; C2Y = 214; CenterY = 174; CenterBias = -20; C3Offset = 134; C3Y = 126; C4X = 868; C4Y = 188; Y6 = 180
    Swing0 = 5; Swing1 = 8; Swing2 = 10; Swing3 = 8; Swing4 = 9; Swing5 = 5; CenterSwing = 7; CenterLift = 5
    XDrift0 = 5; XDrift1 = 9; XDrift2 = 10; XDrift3 = 11; XDrift4 = 10; XDrift5 = 8; XDrift6 = 5
    SpeedA = 0.86; SpeedB = 1.04; SpeedC = 1.12; SpeedD = 0.90; PhaseA = 3.10; PhaseB = 1.70; PhaseC = 4.00; PhaseD = 0.30
    DarkColor = "#5EEAD4"; LightColor = "#14B8A6"; Width = 1.34; DarkGlow = 18; LightGlow = 14; DarkOpacity = 0.54; LightOpacity = 0.62
  },
  @{
    StartX = 230; EndX = 976; Y0 = 102; C1X = 390; C1Y = 72; C2Offset = 108; C2Y = 154; CenterY = 132; CenterBias = 8; C3Offset = 120; C3Y = 88; C4X = 832; C4Y = 68; Y6 = 116
    Swing0 = 4; Swing1 = 7; Swing2 = 9; Swing3 = 6; Swing4 = 7; Swing5 = 4; CenterSwing = 6; CenterLift = 4
    XDrift0 = 4; XDrift1 = 9; XDrift2 = 8; XDrift3 = 10; XDrift4 = 8; XDrift5 = 6; XDrift6 = 4
    SpeedA = 1.02; SpeedB = 0.94; SpeedC = 0.84; SpeedD = 1.10; PhaseA = 4.00; PhaseB = 2.40; PhaseC = 1.60; PhaseD = 2.90
    DarkColor = "#60A5FA"; LightColor = "#2563EB"; Width = 1.24; DarkGlow = 16; LightGlow = 12; DarkOpacity = 0.48; LightOpacity = 0.58
  },
  @{
    StartX = 246; EndX = 986; Y0 = 188; C1X = 374; C1Y = 146; C2Offset = 112; C2Y = 224; CenterY = 184; CenterBias = 18; C3Offset = 128; C3Y = 150; C4X = 856; C4Y = 210; Y6 = 168
    Swing0 = 4; Swing1 = 6; Swing2 = 8; Swing3 = 6; Swing4 = 7; Swing5 = 5; CenterSwing = 5; CenterLift = 3
    XDrift0 = 4; XDrift1 = 8; XDrift2 = 8; XDrift3 = 10; XDrift4 = 8; XDrift5 = 7; XDrift6 = 5
    SpeedA = 0.92; SpeedB = 1.14; SpeedC = 1.02; SpeedD = 0.96; PhaseA = 5.10; PhaseB = 3.30; PhaseC = 2.50; PhaseD = 1.10
    DarkColor = "#22D3EE"; LightColor = "#0EA5E9"; Width = 1.18; DarkGlow = 14; LightGlow = 11; DarkOpacity = 0.42; LightOpacity = 0.56
  },
  @{
    StartX = 214; EndX = 1010; Y0 = 118; C1X = 356; C1Y = 92; C2Offset = 140; C2Y = 130; CenterY = 144; CenterBias = -30; C3Offset = 142; C3Y = 112; C4X = 876; C4Y = 146; Y6 = 138
    Swing0 = 5; Swing1 = 7; Swing2 = 8; Swing3 = 7; Swing4 = 7; Swing5 = 5; CenterSwing = 7; CenterLift = 5
    XDrift0 = 5; XDrift1 = 10; XDrift2 = 10; XDrift3 = 12; XDrift4 = 10; XDrift5 = 8; XDrift6 = 5
    SpeedA = 1.08; SpeedB = 1.00; SpeedC = 0.90; SpeedD = 1.14; PhaseA = 2.70; PhaseB = 4.10; PhaseC = 0.20; PhaseD = 3.00
    DarkColor = "#34D399"; LightColor = "#0EA5A4"; Width = 1.28; DarkGlow = 15; LightGlow = 11; DarkOpacity = 0.46; LightOpacity = 0.58
  },
  @{
    StartX = 172; EndX = 1036; Y0 = 126; C1X = 286; C1Y = 74; C2Offset = 158; C2Y = 180; CenterY = 138; CenterBias = 34; C3Offset = 152; C3Y = 90; C4X = 922; C4Y = 86; Y6 = 126
    Swing0 = 6; Swing1 = 10; Swing2 = 11; Swing3 = 8; Swing4 = 10; Swing5 = 6; CenterSwing = 8; CenterLift = 5
    XDrift0 = 7; XDrift1 = 12; XDrift2 = 13; XDrift3 = 15; XDrift4 = 11; XDrift5 = 9; XDrift6 = 6
    SpeedA = 0.96; SpeedB = 0.82; SpeedC = 1.18; SpeedD = 1.08; PhaseA = 1.70; PhaseB = 5.00; PhaseC = 2.60; PhaseD = 4.00
    DarkColor = "#93C5FD"; LightColor = "#38BDF8"; Width = 1.12; DarkGlow = 12; LightGlow = 10; DarkOpacity = 0.38; LightOpacity = 0.52
  }
)

function Draw-BannerFrame {
  param(
    [System.Windows.Media.DrawingContext]$Context,
    [hashtable]$Theme,
    [double]$Phase
  )

  foreach ($spec in $strandSpecs) {
    $geometry = New-StrandGeometry -Spec $spec -Phase $Phase

    if ($Theme.Name -eq "light") {
      $lineColor = $spec.LightColor
      $lineOpacity = $spec.LightOpacity
      $lineGlow = $spec.LightGlow
    } else {
      $lineColor = $spec.DarkColor
      $lineOpacity = $spec.DarkOpacity
      $lineGlow = $spec.DarkGlow
    }

    $glowPen = [System.Windows.Media.Pen]::new((New-ColorBrush -Color $lineColor -Opacity ($lineGlow / 255.0)), $spec.Width + 1.2)
    $glowPen.StartLineCap = [System.Windows.Media.PenLineCap]::Round
    $glowPen.EndLineCap = [System.Windows.Media.PenLineCap]::Round
    $glowPen.LineJoin = [System.Windows.Media.PenLineJoin]::Round
    $Context.DrawGeometry($null, $glowPen, $geometry)

    $linePen = [System.Windows.Media.Pen]::new((New-ColorBrush -Color $lineColor -Opacity $lineOpacity), $spec.Width)
    $linePen.StartLineCap = [System.Windows.Media.PenLineCap]::Round
    $linePen.EndLineCap = [System.Windows.Media.PenLineCap]::Round
    $linePen.LineJoin = [System.Windows.Media.PenLineJoin]::Round
    $Context.DrawGeometry($null, $linePen, $geometry)
  }

  $titleMeasure = New-FormattedText -Text "Reet Ginotra" -Typeface $titleTypeface -Size 54 -Brush (New-ColorBrush -Color $Theme.TitleFill)
  $subtitleMeasure = New-FormattedText -Text "Full Stack Developer | AI | Product" -Typeface $subtitleTypeface -Size 19 -Brush (New-ColorBrush -Color $Theme.SubtitleFill)

  $titleX = ($width - $titleMeasure.Width) / 2
  $titleY = 100
  $subtitleX = ($width - $subtitleMeasure.Width) / 2
  $subtitleY = 162

  Draw-TextGeometry -Context $Context -Text "Reet Ginotra" -Typeface $titleTypeface -Size 54 -FillColor $Theme.TitleFill -OutlineColor $Theme.TitleOutline -OutlineWidth $Theme.TitleOutlineWidth -ShadowColor $Theme.TitleShadow -ShadowOpacity $Theme.TitleShadowOpacity -ShadowX $Theme.TitleShadowX -ShadowY $Theme.TitleShadowY -X $titleX -Y $titleY
  Draw-TextGeometry -Context $Context -Text "Full Stack Developer | AI | Product" -Typeface $subtitleTypeface -Size 19 -FillColor $Theme.SubtitleFill -OutlineColor $Theme.SubtitleOutline -OutlineWidth $Theme.SubtitleOutlineWidth -ShadowColor $Theme.SubtitleShadow -ShadowOpacity $Theme.SubtitleShadowOpacity -ShadowX $Theme.SubtitleShadowX -ShadowY $Theme.SubtitleShadowY -X $subtitleX -Y $subtitleY
}

foreach ($theme in $outputs) {
  $frames = [System.Collections.Generic.List[System.Windows.Media.Imaging.BitmapFrame]]::new()

  for ($frameIndex = 0; $frameIndex -lt $frameCount; $frameIndex++) {
    $progress = $frameIndex / $frameCount
    $phase = $progress * [Math]::PI * 2.0

    $visual = [System.Windows.Media.DrawingVisual]::new()
    $dc = $visual.RenderOpen()
    Draw-BannerFrame -Context $dc -Theme $theme -Phase $phase
    $dc.Close()

    $bitmap = [System.Windows.Media.Imaging.RenderTargetBitmap]::new($width, $height, $dpi, $dpi, [System.Windows.Media.PixelFormats]::Pbgra32)
    $bitmap.Render($visual)

    if ($frameIndex -eq 0) {
      $previewVisual = [System.Windows.Media.DrawingVisual]::new()
      $previewContext = $previewVisual.RenderOpen()
      $previewContext.DrawRectangle((New-ColorBrush -Color $theme.PreviewBackground), $null, [System.Windows.Rect]::new(0, 0, $width, $height))
      $previewContext.DrawImage($bitmap, [System.Windows.Rect]::new(0, 0, $width, $height))
      $previewContext.Close()

      $previewBitmap = [System.Windows.Media.Imaging.RenderTargetBitmap]::new($width, $height, $dpi, $dpi, [System.Windows.Media.PixelFormats]::Pbgra32)
      $previewBitmap.Render($previewVisual)

      $pngEncoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
      $pngEncoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($previewBitmap))
      $pngStream = [System.IO.File]::Open($theme.PreviewPath, [System.IO.FileMode]::Create)
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

  $gifStream = [System.IO.File]::Open($theme.GifPath, [System.IO.FileMode]::Create)
  try {
    $gifEncoder.Save($gifStream)
  } finally {
    $gifStream.Dispose()
  }

  $gifBytes = [System.IO.File]::ReadAllBytes($theme.GifPath)
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
  [System.IO.File]::WriteAllBytes($theme.GifPath, $combined)
}
