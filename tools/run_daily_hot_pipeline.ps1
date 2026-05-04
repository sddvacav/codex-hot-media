param(
  [int]$Pages = 5,
  [int]$PageSize = 20,
  [int]$TopN = 10
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$collector = Join-Path $root "tools\collect_bilibili_hot.ps1"
$planner = Join-Path $root "tools\make_video_plan_from_hot.ps1"
$dashboardBuilder = Join-Path $root "tools\build_today_dashboard.ps1"
$assetBuilder = Join-Path $root "tools\build_video_assets_from_plan.ps1"
$publishQueueBuilder = Join-Path $root "tools\build_publish_queue.ps1"
$publishPackBuilder = Join-Path $root "tools\build_publish_pack.ps1"
$data = Join-Path $root "data"
$outputs = Join-Path $root "outputs"
$dashboard = Join-Path $root "dashboard_today.html"
$publishQueue = Join-Path $root "publish_queue.html"
$publishPack = Join-Path $root "publish_pack.html"
$videoOut = Join-Path $outputs "generated_videos"
$publishPackOut = Join-Path $outputs "publish_pack"

& powershell -ExecutionPolicy Bypass -File $collector -Pages $Pages -PageSize $PageSize -OutDir $data | Out-Null
& powershell -ExecutionPolicy Bypass -File $planner -InputJson (Join-Path $data "bilibili_hot_latest.json") -OutDir $outputs -TopN $TopN | Out-Null
& powershell -ExecutionPolicy Bypass -File $dashboardBuilder -PlanJson (Join-Path $outputs "video_plan_from_hot_latest.json") -HotJson (Join-Path $data "bilibili_hot_latest.json") -OutHtml $dashboard | Out-Null
& powershell -ExecutionPolicy Bypass -File $assetBuilder -PlanJson (Join-Path $outputs "video_plan_from_hot_latest.json") -OutDir $videoOut -Limit ([Math]::Min(5, $TopN)) | Out-Null
& powershell -ExecutionPolicy Bypass -File $publishQueueBuilder -ManifestJson (Join-Path $videoOut "manifest.json") -PlanJson (Join-Path $outputs "video_plan_from_hot_latest.json") -OutHtml $publishQueue | Out-Null
& powershell -ExecutionPolicy Bypass -File $publishPackBuilder -ManifestJson (Join-Path $videoOut "manifest.json") -PlanJson (Join-Path $outputs "video_plan_from_hot_latest.json") -OutDir $publishPackOut -OutHtml $publishPack | Out-Null

[pscustomobject]@{
  status = "ok"
  hot_report = Join-Path $data "bilibili_hot_latest.md"
  video_plan = Join-Path $outputs "video_plan_from_hot_latest.md"
  dashboard = $dashboard
  publish_queue = $publishQueue
  publish_pack = $publishPack
  publish_pack_markdown = Join-Path $publishPackOut "publish_pack_latest.md"
  publish_log_template = Join-Path $publishPackOut "publish_log_template.csv"
  generated_videos = $videoOut
  generated_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
} | ConvertTo-Json
