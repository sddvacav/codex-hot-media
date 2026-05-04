param(
  [ValidateSet("doctor", "status", "paths", "latest", "run", "collect", "plan", "dashboard", "assets", "queue", "pack")]
  [string]$Action = "doctor",
  [int]$Pages = 5,
  [int]$PageSize = 20,
  [int]$TopN = 10,
  [int]$Limit = 5
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir
$dataDir = Join-Path $root "data"
$outputsDir = Join-Path $root "outputs"
$videoDir = Join-Path $outputsDir "generated_videos"
$publishPackDir = Join-Path $outputsDir "publish_pack"

$paths = [ordered]@{
  root = $root
  data = $dataDir
  outputs = $outputsDir
  collect_script = Join-Path $scriptDir "collect_bilibili_hot.ps1"
  plan_script = Join-Path $scriptDir "make_video_plan_from_hot.ps1"
  dashboard_script = Join-Path $scriptDir "build_today_dashboard.ps1"
  asset_script = Join-Path $scriptDir "build_video_assets_from_plan.ps1"
  queue_script = Join-Path $scriptDir "build_publish_queue.ps1"
  pack_script = Join-Path $scriptDir "build_publish_pack.ps1"
  pipeline_script = Join-Path $scriptDir "run_daily_hot_pipeline.ps1"
  hot_json = Join-Path $dataDir "bilibili_hot_latest.json"
  hot_report = Join-Path $dataDir "bilibili_hot_latest.md"
  plan_json = Join-Path $outputsDir "video_plan_from_hot_latest.json"
  plan_markdown = Join-Path $outputsDir "video_plan_from_hot_latest.md"
  dashboard_html = Join-Path $root "dashboard_today.html"
  publish_queue_html = Join-Path $root "publish_queue.html"
  publish_pack_html = Join-Path $root "publish_pack.html"
  manifest_json = Join-Path $videoDir "manifest.json"
  manifest_markdown = Join-Path $videoDir "manifest.md"
  publish_pack_json = Join-Path $publishPackDir "publish_pack_latest.json"
  publish_pack_markdown = Join-Path $publishPackDir "publish_pack_latest.md"
  publish_log_template = Join-Path $publishPackDir "publish_log_template.csv"
}

function Write-Json($value) {
  $value | ConvertTo-Json -Depth 14
}

function Read-JsonFile($path) {
  if (-not (Test-Path -LiteralPath $path)) { return $null }
  try {
    return Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
  } catch {
    return $null
  }
}

function Get-FileState($path) {
  if (-not (Test-Path -LiteralPath $path)) {
    return [ordered]@{
      path = $path
      exists = $false
      length = 0
      last_write_time = $null
    }
  }

  $item = Get-Item -LiteralPath $path
  return [ordered]@{
    path = $path
    exists = $true
    length = $item.Length
    last_write_time = $item.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
  }
}

function Count-JsonItems($value) {
  if ($null -eq $value) { return 0 }
  return @($value).Count
}

function Invoke-ToolScript($scriptPath, $arguments) {
  if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "Required script not found: $scriptPath"
  }
  $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath @arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Script failed with exit code ${LASTEXITCODE}: $scriptPath"
  }
  return $output
}

function Parse-JsonText($text) {
  if ($null -eq $text) { return $null }
  $joined = ($text | Out-String).Trim()
  if ([string]::IsNullOrWhiteSpace($joined)) { return $null }
  try {
    return $joined | ConvertFrom-Json
  } catch {
    return $null
  }
}

function Get-Status {
  $hot = Read-JsonFile $paths.hot_json
  $plans = Read-JsonFile $paths.plan_json
  $manifest = Read-JsonFile $paths.manifest_json
  $pack = Read-JsonFile $paths.publish_pack_json

  return [ordered]@{
    status = "ok"
    action = "status"
    root = $root
    counts = [ordered]@{
      hot_items = Count-JsonItems $hot
      video_plans = Count-JsonItems $plans
      generated_video_assets = Count-JsonItems $manifest
      publish_pack_items = Count-JsonItems $pack
    }
    files = [ordered]@{
      hot_json = Get-FileState $paths.hot_json
      plan_json = Get-FileState $paths.plan_json
      manifest_json = Get-FileState $paths.manifest_json
      dashboard_html = Get-FileState $paths.dashboard_html
      publish_queue_html = Get-FileState $paths.publish_queue_html
      publish_pack_html = Get-FileState $paths.publish_pack_html
      publish_pack_markdown = Get-FileState $paths.publish_pack_markdown
      publish_log_template = Get-FileState $paths.publish_log_template
    }
    next_safe_actions = @("run", "pack", "latest")
    manual_only = @("platform login", "account authorization", "final publishing", "payment links")
  }
}

try {
  switch ($Action) {
    "doctor" {
      $required = @(
        "collect_script",
        "plan_script",
        "dashboard_script",
        "asset_script",
        "queue_script",
        "pack_script",
        "pipeline_script"
      )
      $checks = foreach ($key in $required) {
        [ordered]@{
          name = $key
          path = $paths[$key]
          exists = Test-Path -LiteralPath $paths[$key]
        }
      }
      $missing = @($checks | Where-Object { -not $_.exists })
      Write-Json ([ordered]@{
        status = if ($missing.Count -eq 0) { "ok" } else { "missing_setup" }
        action = "doctor"
        tool = "codex_media_tool"
        root = $root
        powershell = $PSVersionTable.PSVersion.ToString()
        scripts = $checks
        missing = $missing
        auth_required = $false
        network_used_by = @("collect", "run")
        manual_only = @("no automatic platform login", "no automatic publishing", "no account or payment changes")
      })
    }
    "paths" {
      Write-Json ([ordered]@{
        status = "ok"
        action = "paths"
        paths = $paths
      })
    }
    "status" {
      Write-Json (Get-Status)
    }
    "latest" {
      $plans = @(Read-JsonFile $paths.plan_json)
      $manifest = @(Read-JsonFile $paths.manifest_json)
      $take = [Math]::Min($Limit, $plans.Count)
      $preview = for ($i = 0; $i -lt $take; $i++) {
        $plan = $plans[$i]
        $asset = $manifest | Where-Object { [int]$_.rank -eq [int]$plan.rank } | Select-Object -First 1
        [ordered]@{
          rank = [int]$plan.rank
          source_title = [string]$plan.source_title
          source_category = [string]$plan.source_category
          engagement_score = [double]$plan.engagement_score
          opening_hook = [string]$plan.opening_hook
          conversion = [string]$plan.conversion
          video = if ($null -ne $asset) { [string]$asset.video } else { $null }
          cover = if ($null -ne $asset) { [string]$asset.cover } else { $null }
        }
      }
      Write-Json ([ordered]@{
        status = "ok"
        action = "latest"
        items = $preview
        files = [ordered]@{
          plan_markdown = $paths.plan_markdown
          publish_queue_html = $paths.publish_queue_html
          publish_pack_html = $paths.publish_pack_html
          publish_pack_markdown = $paths.publish_pack_markdown
        }
      })
    }
    "collect" {
      Invoke-ToolScript $paths.collect_script @("-Pages", $Pages, "-PageSize", $PageSize, "-OutDir", $dataDir) | Out-Null
      Write-Json ([ordered]@{
        status = "ok"
        action = "collect"
        hot_json = Get-FileState $paths.hot_json
        hot_report = Get-FileState $paths.hot_report
      })
    }
    "plan" {
      Invoke-ToolScript $paths.plan_script @("-InputJson", $paths.hot_json, "-OutDir", $outputsDir, "-TopN", $TopN) | Out-Null
      Write-Json ([ordered]@{
        status = "ok"
        action = "plan"
        plan_json = Get-FileState $paths.plan_json
        plan_markdown = Get-FileState $paths.plan_markdown
      })
    }
    "dashboard" {
      Invoke-ToolScript $paths.dashboard_script @("-PlanJson", $paths.plan_json, "-HotJson", $paths.hot_json, "-OutHtml", $paths.dashboard_html) | Out-Null
      Write-Json ([ordered]@{
        status = "ok"
        action = "dashboard"
        dashboard_html = Get-FileState $paths.dashboard_html
      })
    }
    "assets" {
      Invoke-ToolScript $paths.asset_script @("-PlanJson", $paths.plan_json, "-OutDir", $videoDir, "-Limit", $Limit) | Out-Null
      Write-Json ([ordered]@{
        status = "ok"
        action = "assets"
        manifest_json = Get-FileState $paths.manifest_json
        manifest_markdown = Get-FileState $paths.manifest_markdown
      })
    }
    "queue" {
      Invoke-ToolScript $paths.queue_script @("-ManifestJson", $paths.manifest_json, "-PlanJson", $paths.plan_json, "-OutHtml", $paths.publish_queue_html) | Out-Null
      Write-Json ([ordered]@{
        status = "ok"
        action = "queue"
        publish_queue_html = Get-FileState $paths.publish_queue_html
      })
    }
    "pack" {
      Invoke-ToolScript $paths.pack_script @("-ManifestJson", $paths.manifest_json, "-PlanJson", $paths.plan_json, "-OutDir", $publishPackDir, "-OutHtml", $paths.publish_pack_html) | Out-Null
      Write-Json ([ordered]@{
        status = "ok"
        action = "pack"
        publish_pack_html = Get-FileState $paths.publish_pack_html
        publish_pack_json = Get-FileState $paths.publish_pack_json
        publish_pack_markdown = Get-FileState $paths.publish_pack_markdown
        publish_log_template = Get-FileState $paths.publish_log_template
      })
    }
    "run" {
      $raw = Invoke-ToolScript $paths.pipeline_script @("-Pages", $Pages, "-PageSize", $PageSize, "-TopN", $TopN)
      $result = Parse-JsonText $raw
      Write-Json ([ordered]@{
        status = "ok"
        action = "run"
        result = $result
        status_after_run = Get-Status
      })
    }
  }
} catch {
  Write-Json ([ordered]@{
    status = "error"
    action = $Action
    message = $_.Exception.Message
  })
  exit 1
}
