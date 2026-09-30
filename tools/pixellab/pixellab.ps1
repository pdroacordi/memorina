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
  [string]$Out = "",
  # An entry of the art prompt library (tools/art/prompts/<id>.md): fills in the
  # description, negative, size, frames, view, direction, styles and reference
  # from the entry and the shared tools/art/prompts/style.md preamble. Explicit
  # parameters still win.
  [string]$Prompt = ""
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

# Reads a library entry: a --- frontmatter of "key: value" lines, then the body;
# a "Negative:" line is the negative prompt. Same format ArtPrompt parses.
function Read-PromptFile([string]$path) {
  if (-not (Test-Path $path)) { throw "No art prompt at $path" }
  $fields = @{}; $body = @(); $negative = ""; $fences = 0
  foreach ($line in Get-Content -LiteralPath $path -Encoding UTF8) {
    if ($line.Trim() -eq "---" -and $fences -lt 2) { $fences++; continue }
    if ($fences -eq 1) {
      $at = $line.IndexOf(":")
      if ($at -gt 0) { $fields[$line.Substring(0, $at).Trim()] = $line.Substring($at + 1).Trim() }
    } elseif ($line.StartsWith("Negative:")) {
      $negative = $line.Substring(9).Trim()
    } else {
      $body += $line
    }
  }
  return @{ Fields = $fields; Body = (($body -join " ").Trim()); Negative = $negative }
}

# Fills this call's parameters from a library entry, leaving any parameter the
# caller passed explicitly alone. A multi-frame "generate" asks for the whole
# sheet in one picture; everything is requested at a whole-number multiple of
# the contract (at least 64 px on its short side) and process_image.gd scales
# it back down, nearest neighbour.
function Use-Prompt([string]$id) {
  $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
  $dir = Join-Path $root "tools\art\prompts"
  $entry = Read-PromptFile (Join-Path $dir "$id.md")
  $style = Read-PromptFile (Join-Path $dir "style.md")
  $f = $entry.Fields
  $bound = $script:PSBoundParameters
  if (-not $bound.ContainsKey("Description")) { $script:Description = "$($style.Fields['preamble']). $($entry.Body)" }
  if (-not $bound.ContainsKey("Negative")) { $script:Negative = (@($style.Fields['negative'], $entry.Negative) | Where-Object { $_ }) -join ", " }
  $size = $f['size'] -split "x"
  $frames = if ($f['frames']) { [int]$f['frames'] } else { 1 }
  $w = [int]$size[0]; $h = [int]$size[1]
  if ($script:Command -eq "generate") { $w = $w * $frames }
  $scale = [Math]::Max(1, [Math]::Ceiling(64 / [Math]::Min($w, $h)))
  if (-not $bound.ContainsKey("Width")) { $script:Width = $w * $scale }
  if (-not $bound.ContainsKey("Height")) { $script:Height = $h * $scale }
  if (-not $bound.ContainsKey("Frames")) { $script:Frames = $frames }
  if (-not $bound.ContainsKey("View") -and $f['view']) { $script:View = $f['view'] }
  if (-not $bound.ContainsKey("Direction") -and $f['direction']) { $script:Direction = $f['direction'] }
  if (-not $bound.ContainsKey("Outline") -and $f['outline']) { $script:Outline = $f['outline'] }
  if (-not $bound.ContainsKey("Shading") -and $f['shading']) { $script:Shading = $f['shading'] }
  if (-not $bound.ContainsKey("Detail") -and $f['detail']) { $script:Detail = $f['detail'] }
  if (-not $bound.ContainsKey("NoBackground") -and $f['no_background'] -eq "true") { $script:NoBackground = [switch]::Present }
  if (-not $bound.ContainsKey("Action") -and $f['action']) { $script:Action = $f['action'] }
  if (-not $bound.ContainsKey("Reference") -and $f['reference']) { $script:Reference = Join-Path $root ($f['reference'] -replace '^res://', '') }
  if (-not $bound.ContainsKey("Name")) { $script:Name = $id }
  Write-Host "prompt $id -> ${script:Width}x${script:Height}, then: godot -s res://tools/art/process_image.gd -- --prompt=$id --in=<png>"
}

if ($Prompt) { Use-Prompt $Prompt }

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
