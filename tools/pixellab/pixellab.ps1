<#
.SYNOPSIS
  Thin PixelLab (https://api.pixellab.ai/v1) client for Memorina's art pipeline.

.DESCRIPTION
  The API key is read ONLY from the PIXELLAB_API_KEY environment variable. It is
  never written to disk, never echoed, never accepted as a parameter, so nothing
  in the repository or in a transcript can carry it.

  Every call costs credits; each response's usage is printed so the spend is
  visible. Generated files land in -Out (default: a pixellab/ folder in the
  system temp dir), never directly in assets/ - moving art into the project is
  a deliberate, reviewed step.

.EXAMPLE
  .\tools\pixellab\pixellab.ps1 balance

.EXAMPLE
  .\tools\pixellab\pixellab.ps1 generate -Description "ice golem boss, side view, dark outline" `
      -Width 128 -Height 128 -NoBackground -Direction west -Out C:\tmp\golem

.EXAMPLE
  .\tools\pixellab\pixellab.ps1 animate -Description "ice golem boss" -Action "taking a hit, flinching" `
      -Reference C:\tmp\golem\generate_0.png -Width 128 -Height 128 -Frames 6 -Direction west `
      -Name frost_guardian_hurt -Out C:\tmp\golem
  # writes frost_guardian_hurt_0.png .. _5.png AND frost_guardian_hurt.png (the horizontal strip
  # Memorina's AnimationPlayer clips expect: hframes = frame count).
#>
[CmdletBinding()]
param(
  [Parameter(Position = 0, Mandatory = $true)]
  [ValidateSet("balance", "generate", "animate")]
  [string]$Command,

  [string]$Description = "",
  [string]$Negative = "",
  [string]$Action = "",
  [string]$Reference = "",
  [int]$Width = 64,
  [int]$Height = 64,
  [int]$Frames = 4,
  [ValidateSet("side", "low top-down", "high top-down")]
  [string]$View = "side",
  [ValidateSet("south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west")]
  [string]$Direction = "west",
  [ValidateSet("", "single color black outline", "single color outline", "selective outline", "lineless")]
  [string]$Outline = "",
  [ValidateSet("", "flat shading", "basic shading", "medium shading", "detailed shading", "highly detailed shading")]
  [string]$Shading = "",
  [ValidateSet("", "low detail", "medium detail", "highly detailed")]
  [string]$Detail = "",
  [switch]$NoBackground,
  [double]$TextGuidance = 8.0,
  [double]$ImageGuidance = 1.5,
  [int]$Seed = 0,
  [string]$Name = "",
  [string]$Out = ""
)

$ErrorActionPreference = "Stop"
$BaseUrl = "https://api.pixellab.ai/v1"

function Get-ApiKey {
  $key = $env:PIXELLAB_API_KEY
  if ([string]::IsNullOrWhiteSpace($key)) {
    throw "PIXELLAB_API_KEY is not set. Set it in this shell only (never in a file): `$env:PIXELLAB_API_KEY = '<key>'"
  }
  return $key
}

function Invoke-PixelLab([string]$Method, [string]$Path, $Body) {
  $headers = @{ Authorization = "Bearer $(Get-ApiKey)" }
  try {
    if ($null -ne $Body) {
      $json = $Body | ConvertTo-Json -Depth 8 -Compress
      return Invoke-RestMethod -Method $Method -Uri "$BaseUrl$Path" -Headers $headers -ContentType "application/json" -Body $json
    }
    return Invoke-RestMethod -Method $Method -Uri "$BaseUrl$Path" -Headers $headers
  } catch {
    $detail = ""
    if ($_.Exception.Response) {
      try { $detail = (New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())).ReadToEnd() } catch {}
    }
    # The key is in the headers, never in the body; the body is safe to show.
    throw "PixelLab $Method $Path failed: $($_.Exception.Message) $detail"
  }
}

function Read-Base64Image([string]$path) {
  if (-not (Test-Path $path)) { throw "Reference image not found: $path" }
  return @{ type = "base64"; base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($path)); format = "png" }
}

function Write-Base64Png($image, [string]$path) {
  [IO.File]::WriteAllBytes($path, [Convert]::FromBase64String($image.base64))
  Write-Host "wrote $path"
}

function Ensure-OutDir {
  if ([string]::IsNullOrWhiteSpace($script:Out)) { $script:Out = Join-Path ([IO.Path]::GetTempPath()) "pixellab" }
  New-Item -ItemType Directory -Force $script:Out | Out-Null
  return $script:Out
}

function Show-Usage($response) {
  if ($response.usage) { Write-Host ("usage: {0:N4} {1}" -f $response.usage.usd, $response.usage.type) }
}

switch ($Command) {
  "balance" {
    $r = Invoke-PixelLab GET "/balance" $null
    Write-Host ("balance: {0:N2} {1}" -f $r.usd, $r.type)
  }

  "generate" {
    if (-not $Description) { throw "-Description is required for generate." }
    $dir = Ensure-OutDir
    $body = @{
      description          = $Description
      negative_description = $Negative
      image_size           = @{ width = $Width; height = $Height }
      text_guidance_scale  = $TextGuidance
      view                 = $View
      direction            = $Direction
      no_background        = [bool]$NoBackground
      isometric            = $false
      seed                 = $Seed
    }
    if ($Outline) { $body.outline = $Outline }
    if ($Shading) { $body.shading = $Shading }
    if ($Detail)  { $body.detail  = $Detail }
    if ($Reference) { $body.init_image = Read-Base64Image $Reference; $body.init_image_strength = 300 }
    $r = Invoke-PixelLab POST "/generate-image-pixflux" $body
    $stem = if ($Name) { $Name } else { "generate" }
    Write-Base64Png $r.image (Join-Path $dir "${stem}_0.png")
    Show-Usage $r
  }

  "animate" {
    if (-not $Description -or -not $Action -or -not $Reference) { throw "animate needs -Description, -Action and -Reference." }
    $dir = Ensure-OutDir
    $body = @{
      image_size           = @{ width = $Width; height = $Height }
      description          = $Description
      action               = $Action
      negative_description = $Negative
      text_guidance_scale  = $TextGuidance
      image_guidance_scale = $ImageGuidance
      n_frames             = $Frames
      start_frame_index    = 0
      view                 = $View
      direction            = $Direction
      reference_image      = Read-Base64Image $Reference
      init_image_strength  = 300
      inpainting_images    = @($null) * $Frames
      seed                 = $Seed
    }
    $r = Invoke-PixelLab POST "/animate-with-text" $body
    $stem = if ($Name) { $Name } else { "animate" }
    $i = 0
    foreach ($img in $r.images) { Write-Base64Png $img (Join-Path $dir ("{0}_{1}.png" -f $stem, $i)); $i++ }
    # Stitch into the horizontal strip Memorina's clips read (Sprite2D.hframes = frame count).
    Add-Type -AssemblyName System.Drawing
    $frames = @(); for ($k = 0; $k -lt $i; $k++) { $frames += [System.Drawing.Bitmap]::FromFile((Join-Path $dir ("{0}_{1}.png" -f $stem, $k))) }
    if ($frames.Count -gt 0) {
      $w = $frames[0].Width; $h = $frames[0].Height
      $strip = New-Object System.Drawing.Bitmap ($w * $frames.Count), $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
      $g = [System.Drawing.Graphics]::FromImage($strip); $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
      for ($k = 0; $k -lt $frames.Count; $k++) { $g.DrawImage($frames[$k], $k * $w, 0, $w, $h); $frames[$k].Dispose() }
      $g.Dispose(); $stripPath = Join-Path $dir "$stem.png"; $strip.Save($stripPath, [System.Drawing.Imaging.ImageFormat]::Png); $strip.Dispose()
      Write-Host "wrote $stripPath ($($frames.Count) frames of ${w}x${h})"
    }
    Show-Usage $r
  }
}
