param(
  [string]$PlanJson = "",
  [string]$HotJson = "",
  [string]$OutHtml = ""
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($PlanJson)) {
  $PlanJson = Join-Path $root "outputs\video_plan_from_hot_latest.json"
}
if ([string]::IsNullOrWhiteSpace($HotJson)) {
  $HotJson = Join-Path $root "data\bilibili_hot_latest.json"
}
if ([string]::IsNullOrWhiteSpace($OutHtml)) {
  $OutHtml = Join-Path $root "dashboard_today.html"
}

function HtmlEncode($value) {
  if ($null -eq $value) { return "" }
  return [System.Net.WebUtility]::HtmlEncode([string]$value)
}

if (-not (Test-Path -LiteralPath $PlanJson)) {
  throw "Plan JSON not found: $PlanJson"
}
if (-not (Test-Path -LiteralPath $HotJson)) {
  throw "Hot JSON not found: $HotJson"
}

$plans = Get-Content -LiteralPath $PlanJson -Raw | ConvertFrom-Json
$hot = Get-Content -LiteralPath $HotJson -Raw | ConvertFrom-Json
$categories = $hot | Group-Object category | Sort-Object Count -Descending | Select-Object -First 10
$topHot = $hot | Sort-Object engagement_score -Descending | Select-Object -First 8

$categoryHtml = foreach ($c in $categories) {
  "<div class='pill'><strong>$(HtmlEncode $c.Name)</strong><span>$($c.Count)</span></div>"
}

$hotRows = foreach ($h in $topHot) {
  "<tr><td><a href='$(HtmlEncode $h.url)' target='_blank'>$(HtmlEncode $h.title)</a></td><td>$(HtmlEncode $h.category)</td><td>$($h.engagement_score)</td><td>$($h.view)</td></tr>"
}

$planCards = foreach ($p in $plans) {
  $titles = ($p.title_options | ForEach-Object { "<li>$(HtmlEncode $_)</li>" }) -join ""
  $shots = ($p.shot_plan | ForEach-Object { "<li>$(HtmlEncode $_)</li>" }) -join ""
  $risks = ($p.risk_check | ForEach-Object { "<span>$(HtmlEncode $_)</span>" }) -join ""
  @"
<article class="plan-card">
  <div class="plan-top">
    <span class="rank">#$($p.rank)</span>
    <span class="score">$($p.engagement_score)</span>
  </div>
  <h3>$(HtmlEncode $p.source_title)</h3>
  <p class="meta">$(HtmlEncode $p.source_category) · <a href="$(HtmlEncode $p.source_url)" target="_blank">source</a></p>
  <p><strong>Angle:</strong> $(HtmlEncode $p.production_angle)</p>
  <p><strong>Hook:</strong> $(HtmlEncode $p.opening_hook)</p>
  <p><strong>Conversion:</strong> $(HtmlEncode $p.conversion)</p>
  <div class="cols">
    <div><h4>Titles</h4><ul>$titles</ul></div>
    <div><h4>Shots</h4><ul>$shots</ul></div>
  </div>
  <p class="voice">$(HtmlEncode $p.voiceover)</p>
  <div class="risks">$risks</div>
</article>
"@
}

$html = @"
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Today Hot Production Dashboard</title>
  <style>
    body { margin: 0; font-family: Arial, "Microsoft YaHei", sans-serif; color: #17202a; background: #f6f7f9; }
    header { padding: 22px; background: #fff; border-bottom: 1px solid #d9e0ea; position: sticky; top: 0; z-index: 5; }
    h1 { margin: 0 0 6px; font-size: 22px; }
    .sub { color: #64748b; font-size: 13px; }
    main { padding: 18px; display: grid; gap: 16px; }
    section { background: #fff; border: 1px solid #d9e0ea; border-radius: 8px; padding: 16px; box-shadow: 0 12px 30px rgba(15, 23, 42, 0.08); }
    h2 { margin: 0 0 12px; font-size: 17px; }
    .pill-grid { display: grid; grid-template-columns: repeat(5, 1fr); gap: 10px; }
    .pill { border: 1px solid #d9e0ea; border-radius: 8px; padding: 10px; background: #fbfcfe; display: flex; justify-content: space-between; gap: 10px; }
    .pill span { color: #2563eb; font-weight: 800; }
    table { width: 100%; border-collapse: collapse; font-size: 13px; }
    th, td { padding: 10px 8px; border-bottom: 1px solid #d9e0ea; text-align: left; }
    th { color: #64748b; background: #fbfcfe; }
    a { color: #2563eb; text-decoration: none; font-weight: 700; }
    .plans { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; }
    .plan-card { border: 1px solid #d9e0ea; border-radius: 8px; padding: 14px; background: #fbfcfe; }
    .plan-top { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
    .rank, .score { border-radius: 999px; padding: 5px 8px; font-size: 12px; font-weight: 800; }
    .rank { background: #eef4ff; color: #2563eb; }
    .score { background: #edf7f3; color: #0f9f6e; }
    h3 { margin: 0 0 6px; font-size: 15px; line-height: 1.4; }
    h4 { margin: 8px 0; font-size: 13px; }
    p, li { font-size: 13px; line-height: 1.55; }
    .meta { color: #64748b; margin-top: 0; }
    .cols { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
    ul { margin: 0; padding-left: 18px; }
    .voice { background: #fff; border: 1px solid #d9e0ea; border-radius: 8px; padding: 10px; }
    .risks { display: flex; flex-wrap: wrap; gap: 8px; }
    .risks span { background: #fff1ee; color: #c2410c; border-radius: 999px; padding: 5px 8px; font-size: 12px; font-weight: 700; }
    @media (max-width: 900px) { .pill-grid, .plans, .cols { grid-template-columns: 1fr; } }
  </style>
</head>
<body>
  <header>
    <h1>Today Hot Production Dashboard</h1>
    <div class="sub">Generated at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') · Source: Bilibili public hot API · Rule: reuse structure, do not copy content</div>
  </header>
  <main>
    <section>
      <h2>Frequent Categories</h2>
      <div class="pill-grid">$($categoryHtml -join "")</div>
    </section>
    <section>
      <h2>High Engagement Hot Items</h2>
      <table>
        <thead><tr><th>Title</th><th>Category</th><th>Score</th><th>Views</th></tr></thead>
        <tbody>$($hotRows -join "")</tbody>
      </table>
    </section>
    <section>
      <h2>Today Video Production Plan</h2>
      <div class="plans">$($planCards -join "")</div>
    </section>
  </main>
</body>
</html>
"@

$html | Set-Content -LiteralPath $OutHtml -Encoding UTF8

[pscustomobject]@{
  status = "ok"
  dashboard = $OutHtml
  plans = $plans.Count
  hot_items = $hot.Count
} | ConvertTo-Json
