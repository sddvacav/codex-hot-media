param(
  [string]$InputJson = "",
  [string]$OutDir = "",
  [int]$TopN = 10
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($InputJson)) {
  $InputJson = Join-Path $root "data\bilibili_hot_latest.json"
}
if ([string]::IsNullOrWhiteSpace($OutDir)) {
  $OutDir = Join-Path $root "outputs"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

if (-not (Test-Path -LiteralPath $InputJson)) {
  throw "Input JSON not found: $InputJson"
}

$items = Get-Content -LiteralPath $InputJson -Raw | ConvertFrom-Json
$ranked = $items | Sort-Object engagement_score -Descending | Select-Object -First $TopN

function Get-Angle($index) {
  $angles = @(
    "extract fandom language and contrast, then convert it into AI workflow storytelling",
    "turn the title into a question-driven explainer for AI tools and knowledge products",
    "reuse the life-contrast structure for a low-budget student AI business diary",
    "extract review and emotional structure, then use it for product teardown content",
    "extract hook, conflict, and payoff, then convert it into a practical AI monetization case"
  )
  return $angles[$index % $angles.Count]
}

function Get-ProductHook($index) {
  $hooks = @(
    "9.9 AI tool list",
    "29 media dashboard template",
    "99 account diagnosis",
    "free comment keyword collection",
    "Bilibili hot report download"
  )
  return $hooks[$index % $hooks.Count]
}

$now = Get-Date -Format "yyyyMMdd_HHmmss"
$jsonPath = Join-Path $OutDir "video_plan_from_hot_$now.json"
$mdPath = Join-Path $OutDir "video_plan_from_hot_$now.md"
$latestJsonPath = Join-Path $OutDir "video_plan_from_hot_latest.json"
$latestMdPath = Join-Path $OutDir "video_plan_from_hot_latest.md"

$plans = @()
$i = 0
foreach ($item in $ranked) {
  $i++
  $angle = Get-Angle $i
  $productHook = Get-ProductHook $i
  $score = [Math]::Round([double]$item.engagement_score, 2)

  $plans += [pscustomobject]@{
    rank = $i
    source_title = $item.title
    source_url = $item.url
    source_category = $item.category
    engagement_score = $score
    production_angle = $angle
    platform_versions = @("douyin_60s", "bilibili_3min", "xiaohongshu_note")
    title_options = @(
      "I studied why this hot video works, and turned it into an AI monetization topic",
      "Do not copy this hot topic. Extract this structure instead",
      "How ordinary students can reuse hot-topic structure for an AI product"
    )
    opening_hook = "Do not copy trending videos. Copy the structure, then replace it with your own test and product."
    shot_plan = @(
      "show the hot topic title and blur nonessential details",
      "mark the hook, conflict, and payoff",
      "convert the structure into an AI media workflow",
      "show the template or low-price product",
      "end with a comment keyword"
    )
    voiceover = "This video is hot because it has a clear hook, a strong emotional gap, and a payoff. For our account, we do not copy the content. We extract the structure and turn it into a real AI workflow: collect a trend, generate a script, make a template, and test whether users ask for it. If there is demand, it becomes a small paid product."
    conversion = $productHook
    risk_check = @(
      "do not reuse original footage",
      "do not copy exact title",
      "add your own screen recording or dashboard demo",
      "avoid income guarantees"
    )
  }
}

$plans | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8
$plans | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $latestJsonPath -Encoding UTF8

$lines = @(
  "# Video Plan From Hot Trends",
  "",
  "Generated at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
  "",
  "Input: $InputJson",
  "",
  "Rule: reuse trend structure, not original content.",
  ""
)

foreach ($p in $plans) {
  $lines += "## $($p.rank). $($p.source_title)"
  $lines += ""
  $lines += "- Source: $($p.source_url)"
  $lines += "- Category: $($p.source_category)"
  $lines += "- Engagement score: $($p.engagement_score)"
  $lines += "- Production angle: $($p.production_angle)"
  $lines += "- Opening hook: $($p.opening_hook)"
  $lines += "- Conversion: $($p.conversion)"
  $lines += ""
  $lines += "Title options:"
  foreach ($title in $p.title_options) {
    $lines += "- $title"
  }
  $lines += ""
  $lines += "Shot plan:"
  foreach ($shot in $p.shot_plan) {
    $lines += "- $shot"
  }
  $lines += ""
  $lines += "Voiceover:"
  $lines += ""
  $lines += $p.voiceover
  $lines += ""
  $lines += "Risk check:"
  foreach ($risk in $p.risk_check) {
    $lines += "- $risk"
  }
  $lines += ""
}

$lines -join [Environment]::NewLine | Set-Content -LiteralPath $mdPath -Encoding UTF8
$lines -join [Environment]::NewLine | Set-Content -LiteralPath $latestMdPath -Encoding UTF8

[pscustomobject]@{
  count = $plans.Count
  json = $jsonPath
  markdown = $mdPath
  latest_json = $latestJsonPath
  latest_markdown = $latestMdPath
} | ConvertTo-Json
