param(
  [string]$ManifestJson = "",
  [string]$PlanJson = "",
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
if ([string]::IsNullOrWhiteSpace($OutHtml)) {
  $OutHtml = Join-Path $projectRoot "publish_queue.html"
}

function HtmlEncode($value) {
  if ($null -eq $value) { return "" }
  return [System.Net.WebUtility]::HtmlEncode([string]$value)
}

function RelPath($path) {
  $root = "$projectRoot\"
  return ([string]$path).Replace($root, "").Replace("\", "/")
}

if (-not (Test-Path -LiteralPath $ManifestJson)) {
  throw "Manifest JSON not found: $ManifestJson"
}
if (-not (Test-Path -LiteralPath $PlanJson)) {
  throw "Plan JSON not found: $PlanJson"
}

$manifest = Get-Content -LiteralPath $ManifestJson -Raw | ConvertFrom-Json
$plans = Get-Content -LiteralPath $PlanJson -Raw | ConvertFrom-Json

$cards = foreach ($item in $manifest) {
  $plan = $plans | Where-Object { [int]$_.rank -eq [int]$item.rank } | Select-Object -First 1
  $video = RelPath $item.video
  $cover = RelPath $item.cover
  $title = if ($plan.title_options.Count -gt 0) { $plan.title_options[0] } else { "Hot structure to AI product" }
  $desc = "Do not copy hot videos. Extract the structure, show your own AI workflow, and turn it into a small useful product. Comment keyword: AI."
  $tags = "#AI #selfmedia #knowledgeproduct #studentbudget #workflow"
  $hook = $plan.opening_hook
  $conversion = $item.conversion

  @"
<article class="queue-card">
  <div class="media">
    <video src="$video" poster="$cover" controls muted playsinline></video>
  </div>
  <div class="queue-body">
    <div class="topline">
      <span class="rank">Plan $($item.rank)</span>
      <span class="status">manual review</span>
    </div>
    <h3>$(HtmlEncode $item.source_title)</h3>
    <p class="muted">Conversion: $(HtmlEncode $conversion)</p>
    <label>Title</label>
    <textarea readonly>$(HtmlEncode $title)</textarea>
    <label>Description</label>
    <textarea readonly>$(HtmlEncode $desc)</textarea>
    <label>Tags</label>
    <input readonly value="$(HtmlEncode $tags)" />
    <label>Opening Hook</label>
    <textarea readonly>$(HtmlEncode $hook)</textarea>
    <div class="actions">
      <button data-copy="$(HtmlEncode $title)">Copy title</button>
      <button data-copy="$(HtmlEncode $desc)">Copy description</button>
      <button data-copy="$(HtmlEncode $tags)">Copy tags</button>
    </div>
    <div class="checklist">
      <label><input type="checkbox" /> I own the account and will publish manually</label>
      <label><input type="checkbox" /> No original footage reused</label>
      <label><input type="checkbox" /> No income guarantee</label>
      <label><input type="checkbox" /> Title and description reviewed</label>
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
  <title>Publish Queue</title>
  <style>
    body { margin: 0; font-family: Arial, "Microsoft YaHei", sans-serif; background: #f6f7f9; color: #17202a; }
    header { background: #fff; border-bottom: 1px solid #d9e0ea; padding: 18px 22px; position: sticky; top: 0; z-index: 10; display: flex; justify-content: space-between; gap: 16px; align-items: center; }
    h1 { margin: 0 0 5px; font-size: 21px; }
    .sub { color: #64748b; font-size: 12px; }
    a { color: #2563eb; text-decoration: none; font-weight: 800; font-size: 12px; }
    main { padding: 16px; display: grid; gap: 16px; }
    .queue-card { background: #fff; border: 1px solid #d9e0ea; border-radius: 8px; box-shadow: 0 12px 30px rgba(15, 23, 42, 0.08); display: grid; grid-template-columns: 260px 1fr; overflow: hidden; }
    .media { background: #111827; padding: 12px; display: grid; place-items: center; }
    video { width: 100%; max-height: 460px; aspect-ratio: 9 / 16; background: #111827; border-radius: 8px; }
    .queue-body { padding: 14px; }
    .topline { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
    .rank, .status { border-radius: 999px; padding: 5px 8px; font-size: 12px; font-weight: 800; }
    .rank { background: #eef4ff; color: #2563eb; }
    .status { background: #fff8e6; color: #b7791f; }
    h3 { margin: 0 0 8px; font-size: 15px; line-height: 1.4; }
    .muted { margin: 0 0 12px; color: #64748b; font-size: 12px; }
    label { display: block; margin: 9px 0 5px; color: #64748b; font-weight: 800; font-size: 12px; }
    textarea, input { width: 100%; border: 1px solid #d9e0ea; border-radius: 8px; padding: 9px; font: inherit; font-size: 12px; background: #fbfcfe; color: #17202a; }
    textarea { min-height: 58px; resize: vertical; line-height: 1.45; }
    .actions { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 10px; }
    button { border: 1px solid #d9e0ea; background: #fff; border-radius: 8px; padding: 9px 11px; font-weight: 800; cursor: pointer; }
    .checklist { display: grid; grid-template-columns: repeat(2, 1fr); gap: 8px; margin-top: 12px; padding: 10px; background: #fbfcfe; border: 1px solid #d9e0ea; border-radius: 8px; }
    .checklist label { color: #17202a; margin: 0; font-weight: 700; display: flex; align-items: center; gap: 7px; }
    .toast { position: fixed; right: 16px; bottom: 16px; background: #17202a; color: #fff; border-radius: 8px; padding: 10px 12px; font-size: 12px; display: none; }
    @media (max-width: 860px) { .queue-card { grid-template-columns: 1fr; } .checklist { grid-template-columns: 1fr; } }
  </style>
</head>
<body>
  <header>
    <div>
      <h1>Publish Queue</h1>
      <div class="sub">Generated at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') · Draft videos require manual account review before publishing.</div>
    </div>
    <a href="index.html">Back to dashboard</a>
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
  publish_queue = $OutHtml
  items = $manifest.Count
} | ConvertTo-Json
