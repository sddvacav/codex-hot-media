param(
  [string]$ManifestJson = "",
  [string]$PlanJson = "",
  [string]$OutDir = "",
  [string]$OutHtml = ""
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ManifestJson)) {
  $ManifestJson = Join-Path $projectRoot "outputs\generated_videos\manifest.json"
}
if ([string]::IsNullOrWhiteSpace($PlanJson)) {
  $PlanJson = Join-Path $projectRoot "outputs\video_plan_from_hot_latest.json"
}
if ([string]::IsNullOrWhiteSpace($OutDir)) {
  $OutDir = Join-Path $projectRoot "outputs\publish_pack"
}
if ([string]::IsNullOrWhiteSpace($OutHtml)) {
  $OutHtml = Join-Path $projectRoot "publish_pack.html"
}

function HtmlEncode($value) {
  if ($null -eq $value) { return "" }
  return [System.Net.WebUtility]::HtmlEncode([string]$value)
}

function RelPath($path) {
  $root = "$projectRoot\"
  return ([string]$path).Replace($root, "").Replace("\", "/")
}

function FirstOrDefault($values, $fallback) {
  if ($null -ne $values -and $values.Count -gt 0) { return [string]$values[0] }
  return $fallback
}

if (-not (Test-Path -LiteralPath $ManifestJson)) {
  throw "Manifest JSON not found: $ManifestJson"
}
if (-not (Test-Path -LiteralPath $PlanJson)) {
  throw "Plan JSON not found: $PlanJson"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$manifest = Get-Content -LiteralPath $ManifestJson -Raw | ConvertFrom-Json
$plans = Get-Content -LiteralPath $PlanJson -Raw | ConvertFrom-Json
$generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$items = @()
$logRows = @()

foreach ($asset in $manifest) {
  $plan = $plans | Where-Object { [int]$_.rank -eq [int]$asset.rank } | Select-Object -First 1
  if ($null -eq $plan) { continue }

  $baseTitle = FirstOrDefault $plan.title_options "Turn a hot topic into an original AI workflow"
  $hook = [string]$plan.opening_hook
  $angle = [string]$plan.production_angle
  $conversion = [string]$asset.conversion
  $sourceCategory = [string]$plan.source_category
  $commonDisclosure = "Original remake plan. No source footage reused. Manual review required before publishing."

  $platforms = [ordered]@{
    douyin = [ordered]@{
      title = "Do not copy hot videos: reuse the structure"
      description = "$hook`n`nSource category: $sourceCategory`nAngle: $angle`nCTA: comment AI to get $conversion.`n`n$commonDisclosure"
      tags = "#AI #selfmedia #hotstructure #workflow #knowledgeproduct"
      first_comment = "Keyword: AI. Send resources only after manual review."
    }
    bilibili = [ordered]@{
      title = "How I turned a hot-video structure into an AI media workflow"
      description = "$baseTitle`n`nThis is a teardown of hook, conflict, pacing, and payoff. Use your own dashboard demo, screen recording, or product test.`n`nConversion: $conversion`n$commonDisclosure"
      tags = "AI,selfmedia,hot-topic-analysis,knowledge-product,workflow"
      first_comment = "Download or request the checklist only after the draft passes manual review."
    }
    xiaohongshu = [ordered]@{
      title = "Hot-topic structure to original content workflow"
      description = "I do not reuse the hot video itself. I only extract the hook structure, then replace it with my own AI workflow demo.`n`n1. Find the hook`n2. Convert it into a question`n3. Show the workflow`n4. Offer a small useful template`n`nCTA: $conversion"
      tags = "#AI #hot-topic #content-ops #knowledge-product #low-budget-creator"
      first_comment = "Manual review note: check facts, platform rules, and original material before posting."
    }
  }

  $checklist = @(
    "Video and cover open correctly",
    "No source footage reused",
    "Title is not copied from the source",
    "Facts and claims reviewed",
    "No income guarantee",
    "Account owner publishes manually"
  )

  $items += [pscustomobject]@{
    rank = [int]$asset.rank
    source_title = [string]$asset.source_title
    source_url = [string]$plan.source_url
    source_category = $sourceCategory
    engagement_score = [double]$plan.engagement_score
    video = [string]$asset.video
    cover = [string]$asset.cover
    conversion = $conversion
    review_status = "manual_review_required"
    platforms = $platforms
    checklist = $checklist
  }

  foreach ($platform in @("douyin", "bilibili", "xiaohongshu")) {
    $logRows += [pscustomobject]@{
      rank = [int]$asset.rank
      platform = $platform
      status = "draft"
      publish_time = ""
      post_url = ""
      views = ""
      likes = ""
      comments = ""
      followers_delta = ""
      notes = ""
    }
  }
}

$jsonPath = Join-Path $OutDir "publish_pack_latest.json"
$mdPath = Join-Path $OutDir "publish_pack_latest.md"
$csvPath = Join-Path $OutDir "publish_log_template.csv"

$items | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $jsonPath -Encoding UTF8
$logRows | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Publish Content Pack")
$md.Add("")
$md.Add("Generated at: $generatedAt")
$md.Add("")
$md.Add("Use this pack for manual publishing only. Review every item before posting.")
$md.Add("")
foreach ($item in $items) {
  $md.Add("## Plan $($item.rank)")
  $md.Add("")
  $md.Add("- Source title: $($item.source_title)")
  $md.Add("- Source category: $($item.source_category)")
  $md.Add("- Engagement score: $($item.engagement_score)")
  $md.Add("- Video: $($item.video)")
  $md.Add("- Cover: $($item.cover)")
  $md.Add("- Conversion: $($item.conversion)")
  $md.Add("- Review status: $($item.review_status)")
  $md.Add("")
  foreach ($platform in @("douyin", "bilibili", "xiaohongshu")) {
    $copy = $item.platforms[$platform]
    $md.Add("### $platform")
    $md.Add("")
    $md.Add("Title: $($copy.title)")
    $md.Add("")
    $md.Add("Description:")
    $md.Add("")
    $md.Add('```text')
    $md.Add($copy.description)
    $md.Add('```')
    $md.Add("")
    $md.Add("Tags: $($copy.tags)")
    $md.Add("")
    $md.Add("First comment: $($copy.first_comment)")
    $md.Add("")
  }
  $md.Add("Checklist:")
  foreach ($check in $item.checklist) {
    $md.Add("- [ ] $check")
  }
  $md.Add("")
}
$md | Set-Content -LiteralPath $mdPath -Encoding UTF8

$cards = foreach ($item in $items) {
  $video = RelPath $item.video
  $cover = RelPath $item.cover
  $platformBlocks = foreach ($platform in @("douyin", "bilibili", "xiaohongshu")) {
    $copy = $item.platforms[$platform]
    $copyText = "$($copy.title)`n`n$($copy.description)`n`n$($copy.tags)`n`n$($copy.first_comment)"
    @"
<section class="platform-block">
  <div class="platform-head">
    <strong>$(HtmlEncode $platform)</strong>
    <button data-copy="$(HtmlEncode $copyText)">Copy pack</button>
  </div>
  <label>Title</label>
  <textarea readonly>$(HtmlEncode $copy.title)</textarea>
  <label>Description</label>
  <textarea readonly class="desc">$(HtmlEncode $copy.description)</textarea>
  <label>Tags</label>
  <input readonly value="$(HtmlEncode $copy.tags)" />
  <label>First comment</label>
  <textarea readonly>$(HtmlEncode $copy.first_comment)</textarea>
</section>
"@
  }

  $checks = foreach ($check in $item.checklist) {
    "<label><input type=""checkbox"" /> $(HtmlEncode $check)</label>"
  }

  @"
<article class="pack-card">
  <div class="asset-panel">
    <video src="$video" poster="$cover" controls muted playsinline></video>
    <a href="$video" target="_blank" rel="noreferrer">Open video</a>
    <a href="$cover" target="_blank" rel="noreferrer">Open cover</a>
  </div>
  <div class="pack-body">
    <div class="topline">
      <span class="rank">Plan $($item.rank)</span>
      <span class="status">manual review</span>
    </div>
    <h2>$(HtmlEncode $item.source_title)</h2>
    <p class="meta">Category: $(HtmlEncode $item.source_category) | Score: $($item.engagement_score) | Conversion: $(HtmlEncode $item.conversion)</p>
    <div class="platform-grid">
      $($platformBlocks -join [Environment]::NewLine)
    </div>
    <div class="checklist">
      $($checks -join [Environment]::NewLine)
    </div>
  </div>
</article>
"@
}

$html = @"
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Publish Content Pack</title>
  <style>
    body { margin: 0; font-family: Arial, "Microsoft YaHei", sans-serif; background: #f6f7f9; color: #17202a; }
    header { background: #fff; border-bottom: 1px solid #d9e0ea; padding: 18px 22px; position: sticky; top: 0; z-index: 10; display: flex; justify-content: space-between; gap: 16px; align-items: center; }
    h1 { margin: 0 0 5px; font-size: 21px; letter-spacing: 0; }
    .sub { color: #64748b; font-size: 12px; }
    a { color: #2563eb; text-decoration: none; font-weight: 800; font-size: 12px; }
    main { padding: 16px; display: grid; gap: 16px; }
    .pack-card { background: #fff; border: 1px solid #d9e0ea; border-radius: 8px; box-shadow: 0 12px 30px rgba(15, 23, 42, 0.08); display: grid; grid-template-columns: 230px 1fr; overflow: hidden; }
    .asset-panel { background: #111827; padding: 12px; display: grid; gap: 10px; align-content: start; }
    .asset-panel a { color: #dbeafe; }
    video { width: 100%; max-height: 420px; aspect-ratio: 9 / 16; background: #111827; border-radius: 8px; }
    .pack-body { padding: 14px; }
    .topline { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
    .rank, .status { border-radius: 999px; padding: 5px 8px; font-size: 12px; font-weight: 800; }
    .rank { background: #eef4ff; color: #2563eb; }
    .status { background: #fff8e6; color: #b7791f; }
    h2 { margin: 0 0 8px; font-size: 15px; line-height: 1.4; letter-spacing: 0; }
    .meta { margin: 0 0 12px; color: #64748b; font-size: 12px; }
    .platform-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; }
    .platform-block { border: 1px solid #d9e0ea; border-radius: 8px; padding: 10px; background: #fbfcfe; }
    .platform-head { display: flex; justify-content: space-between; align-items: center; gap: 8px; margin-bottom: 8px; }
    label { display: block; margin: 8px 0 5px; color: #64748b; font-weight: 800; font-size: 12px; }
    textarea, input { width: 100%; border: 1px solid #d9e0ea; border-radius: 8px; padding: 9px; font: inherit; font-size: 12px; background: #fff; color: #17202a; }
    textarea { min-height: 64px; resize: vertical; line-height: 1.45; }
    textarea.desc { min-height: 132px; }
    button { border: 1px solid #d9e0ea; background: #fff; border-radius: 8px; padding: 8px 10px; font-weight: 800; cursor: pointer; font-size: 12px; }
    .checklist { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; margin-top: 12px; padding: 10px; background: #fff; border: 1px solid #d9e0ea; border-radius: 8px; }
    .checklist label { color: #17202a; margin: 0; font-weight: 700; display: flex; align-items: center; gap: 7px; }
    .toast { position: fixed; right: 16px; bottom: 16px; background: #17202a; color: #fff; border-radius: 8px; padding: 10px 12px; font-size: 12px; display: none; }
    @media (max-width: 1100px) { .pack-card { grid-template-columns: 1fr; } .platform-grid { grid-template-columns: 1fr; } .checklist { grid-template-columns: 1fr; } }
  </style>
</head>
<body>
  <header>
    <div>
      <h1>Publish Content Pack</h1>
      <div class="sub">Generated at $generatedAt. Copy is prepared for manual publishing; this page does not post to any platform.</div>
    </div>
    <div>
      <a href="publish_queue.html">Publish queue</a>
      &nbsp;|&nbsp;
      <a href="index.html">Dashboard</a>
    </div>
  </header>
  <main>
    $($cards -join [Environment]::NewLine)
  </main>
  <div class="toast" id="toast">Copied</div>
  <script>
    const toast = document.getElementById("toast");
    document.querySelectorAll("button[data-copy]").forEach((button) => {
      button.addEventListener("click", async () => {
        const text = button.getAttribute("data-copy");
        try {
          await navigator.clipboard.writeText(text);
        } catch {
          const input = document.createElement("textarea");
          input.value = text;
          document.body.appendChild(input);
          input.select();
          document.execCommand("copy");
          input.remove();
        }
        toast.style.display = "block";
        setTimeout(() => toast.style.display = "none", 1200);
      });
    });
  </script>
</body>
</html>
"@

$html | Set-Content -LiteralPath $OutHtml -Encoding UTF8

[pscustomobject]@{
  status = "ok"
  publish_pack = $mdPath
  publish_pack_json = $jsonPath
  publish_log_template = $csvPath
  publish_pack_page = $OutHtml
  items = $items.Count
  generated_at = $generatedAt
} | ConvertTo-Json
