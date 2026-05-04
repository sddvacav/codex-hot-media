param(
  [int]$Pages = 3,
  [int]$PageSize = 20,
  [string]$OutDir = ""
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($OutDir)) {
  $OutDir = Join-Path $root "data"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$headers = @{
  "User-Agent" = "Mozilla/5.0"
  "Referer" = "https://www.bilibili.com/v/popular/all/"
}

$items = @()

for ($page = 1; $page -le $Pages; $page++) {
  $uri = "https://api.bilibili.com/x/web-interface/popular?ps=$PageSize&pn=$page"
  $response = Invoke-RestMethod -Uri $uri -Headers $headers -TimeoutSec 15
  if ($response.code -ne 0) {
    throw "Bilibili API returned code $($response.code): $($response.message)"
  }

  foreach ($video in $response.data.list) {
    $view = [double][Math]::Max([int64]$video.stat.view, 1)
    $engagement = [Math]::Round(
      (($video.stat.like + $video.stat.coin * 2 + $video.stat.favorite * 1.5 + $video.stat.reply * 1.2 + $video.stat.share * 1.5) / $view) * 100,
      2
    )

    $items += [pscustomobject]@{
      source = "bilibili"
      title = $video.title
      category = $video.tname
      sub_category = $video.tnamev2
      author = $video.owner.name
      bvid = $video.bvid
      url = "https://www.bilibili.com/video/$($video.bvid)"
      duration_seconds = [int]$video.duration
      view = [int64]$video.stat.view
      like = [int64]$video.stat.like
      coin = [int64]$video.stat.coin
      favorite = [int64]$video.stat.favorite
      reply = [int64]$video.stat.reply
      share = [int64]$video.stat.share
      engagement_score = $engagement
      production_angle = ""
    }
  }
}

$now = Get-Date -Format "yyyyMMdd_HHmmss"
$jsonPath = Join-Path $OutDir "bilibili_hot_$now.json"
$mdPath = Join-Path $OutDir "bilibili_hot_$now.md"
$latestJsonPath = Join-Path $OutDir "bilibili_hot_latest.json"
$latestMdPath = Join-Path $OutDir "bilibili_hot_latest.md"

$ranked = $items | Sort-Object engagement_score -Descending
$items | ConvertTo-Json -Depth 5 | Set-Content -Path $jsonPath -Encoding UTF8
$items | ConvertTo-Json -Depth 5 | Set-Content -Path $latestJsonPath -Encoding UTF8

$categoryLines = $items |
  Group-Object category |
  Sort-Object Count -Descending |
  Select-Object -First 12 |
  ForEach-Object { "- $($_.Name): $($_.Count)" }

$topLines = $ranked |
  Select-Object -First 20 |
  ForEach-Object {
    "- [$($_.title)]($($_.url)) | $($_.category) | score $($_.engagement_score) | views $($_.view) | likes $($_.like)"
  }

$reportLines = @(
  "# Bilibili Hot Report",
  "",
  "Collected at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
  "",
  "Scope: $Pages pages, $PageSize items per page, total $($items.Count) items.",
  "",
  "## Frequent Categories",
  "",
  ($categoryLines -join "`n"),
  "",
  "## High Engagement Candidates",
  "",
  ($topLines -join "`n"),
  "",
  "## Production Rules",
  "",
  "1. Do not copy titles directly. Extract structure only.",
  "2. Prefer question, contrast, tool, and review formats.",
  "3. Convert each trend into your own test, opinion, template, or workflow.",
  "4. Put only high-engagement and monetizable topics into the production queue."
)

$report = $reportLines -join [Environment]::NewLine
$report | Set-Content -Path $mdPath -Encoding UTF8
$report | Set-Content -Path $latestMdPath -Encoding UTF8

[pscustomobject]@{
  count = $items.Count
  json = $jsonPath
  markdown = $mdPath
  latest_json = $latestJsonPath
  latest_markdown = $latestMdPath
} | ConvertTo-Json
