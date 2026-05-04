param(
  [string]$PlanJson = "",
  [string]$OutDir = "",
  [int]$Limit = 5
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($PlanJson)) {
  $PlanJson = Join-Path $root "outputs\video_plan_from_hot_latest.json"
}
if ([string]::IsNullOrWhiteSpace($OutDir)) {
  $OutDir = Join-Path $root "outputs\generated_videos"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

if (-not (Test-Path -LiteralPath $PlanJson)) {
  throw "Plan JSON not found: $PlanJson"
}

$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpeg) {
  throw "ffmpeg not found in PATH"
}

$font = "C\:/Windows/Fonts/msyh.ttc"
$plans = Get-Content -LiteralPath $PlanJson -Raw | ConvertFrom-Json
$selected = $plans | Select-Object -First $Limit

function SafeName($value) {
  $text = [string]$value
  $text = $text -replace '[\\/:*?"<>|]', '_'
  $text = $text -replace '\s+', '_'
  if ($text.Length -gt 36) {
    $text = $text.Substring(0, 36)
  }
  return $text.Trim('_')
}

function Run-Ffmpeg($arguments) {
  $oldErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  & ffmpeg @arguments *> $null
  $ErrorActionPreference = $oldErrorActionPreference
  if ($LASTEXITCODE -ne 0) {
    throw "ffmpeg failed with exit code $LASTEXITCODE"
  }
}

$manifest = @()

foreach ($plan in $selected) {
  $rank = [int]$plan.rank
  $name = "plan_{0:D2}_{1}" -f $rank, (SafeName $plan.conversion)
  $mp4 = Join-Path $OutDir "$name.mp4"
  $cover = Join-Path $OutDir "$name.jpg"

  $slide1 = "Hot structure #{0}" -f $rank
  $slide2 = "Do not copy content"
  $slide3 = "Rebuild with your AI workflow"
  $slide4 = "Build a small paid product"

  $filter = "[0:v]drawtext=fontfile='$font':text='$slide1':fontcolor=0x17202a:fontsize=82:x=(w-text_w)/2:y=610,drawtext=fontfile='$font':text='Extract hook and conflict':fontcolor=0x64748b:fontsize=42:x=(w-text_w)/2:y=760[a];" +
    "[1:v]drawtext=fontfile='$font':text='$slide2':fontcolor=white:fontsize=78:x=(w-text_w)/2:y=650,drawtext=fontfile='$font':text='Only reuse structure':fontcolor=white:fontsize=42:x=(w-text_w)/2:y=790[b];" +
    "[2:v]drawtext=fontfile='$font':text='$slide3':fontcolor=white:fontsize=62:x=(w-text_w)/2:y=640,drawtext=fontfile='$font':text='Show dashboard, test, template':fontcolor=white:fontsize=40:x=(w-text_w)/2:y=790[c];" +
    "[3:v]drawtext=fontfile='$font':text='$slide4':fontcolor=0x17202a:fontsize=58:x=(w-text_w)/2:y=650,drawtext=fontfile='$font':text='Comment keyword for resource':fontcolor=0x2563eb:fontsize=40:x=(w-text_w)/2:y=800[d];" +
    "[a][b][c][d]concat=n=4:v=1:a=0,format=yuv420p[v]"

  $videoArgs = @(
    "-y",
    "-f", "lavfi", "-i", "color=c=0xf6f7f9:s=1080x1920:d=3",
    "-f", "lavfi", "-i", "color=c=0x17202a:s=1080x1920:d=3",
    "-f", "lavfi", "-i", "color=c=0x2563eb:s=1080x1920:d=3",
    "-f", "lavfi", "-i", "color=c=0xfffbeb:s=1080x1920:d=3",
    "-filter_complex", $filter,
    "-map", "[v]",
    "-r", "30",
    $mp4
  )

  Run-Ffmpeg $videoArgs

  $coverFilter = "drawtext=fontfile='$font':text='AI Media Plan $rank':fontcolor=0x17202a:fontsize=78:x=(w-text_w)/2:y=560,drawtext=fontfile='$font':text='Hot structure to product':fontcolor=0x2563eb:fontsize=50:x=(w-text_w)/2:y=700,drawtext=fontfile='$font':text='Draft asset':fontcolor=0x64748b:fontsize=42:x=(w-text_w)/2:y=820"
  $coverArgs = @(
    "-y",
    "-f", "lavfi", "-i", "color=c=0xf6f7f9:s=1080x1920:d=1",
    "-frames:v", "1",
    "-vf", $coverFilter,
    $cover
  )

  Run-Ffmpeg $coverArgs

  $manifest += [pscustomobject]@{
    rank = $rank
    source_title = $plan.source_title
    conversion = $plan.conversion
    video = $mp4
    cover = $cover
  }
}

$manifestPath = Join-Path $OutDir "manifest.json"
$manifestMdPath = Join-Path $OutDir "manifest.md"
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

$lines = @(
  "# Generated Video Assets",
  "",
  "Generated at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
  "",
  "These are draft assets. Review content, add voice, and confirm platform rules before publishing.",
  ""
)

foreach ($item in $manifest) {
  $lines += "## Plan $($item.rank)"
  $lines += ""
  $lines += "- Source title: $($item.source_title)"
  $lines += "- Conversion: $($item.conversion)"
  $lines += "- Video: $($item.video)"
  $lines += "- Cover: $($item.cover)"
  $lines += ""
}

$lines -join [Environment]::NewLine | Set-Content -LiteralPath $manifestMdPath -Encoding UTF8

[pscustomobject]@{
  status = "ok"
  count = $manifest.Count
  out_dir = $OutDir
  manifest = $manifestPath
  markdown = $manifestMdPath
} | ConvertTo-Json
