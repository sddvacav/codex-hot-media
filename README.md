# codex-hot-media

Codex and Claude Code friendly CLI for turning public hot lists into original short-video plans and manual publish packs.

It is designed for agent workflows: every command emits stable JSON, writes predictable files, and avoids platform login, cookies, account automation, payment links, and automatic publishing.

## What It Uses

Current-source pass on 2026-05-04:

- `imsyy/DailyHotApi` HEAD: `36c77e3bd891c11642d314cfb229bf31646704de`
- `DIYgod/RSSHub` HEAD: `566f028aaf1813c9d05e491b9f6c67325a06e837`
- `SocialSisterYi/bilibili-API-collect` HEAD: `4c00347d4f3494318903eeb11fb00d7b9c1f8c68`
- `tophubs/TopList` HEAD: `44e550cf3a4bcfe2ec1adc668fa6adb8fd453f9c`
- `ourongxing/newsnow` HEAD: `625bf04bc9ec13acd5554d241fa1683b0506027a`
- `joyce677/TrendRadar` HEAD: `7b33d53f8233b4056c4e033178f70f135f2d156a`
- `one-box-u/openclaw-daily-hot-news` HEAD: `93aa62ab874cfb8ccd6a5d662b40a0942b685027`

Supported input patterns:

- Bilibili public popular endpoint.
- Self-hosted DailyHotApi JSON routes.
- Self-hosted RSSHub RSS/Atom routes.
- Self-hosted NewsNow / TrendRadar / OpenClaw daily hot news JSON exports.
- Any generic JSON URL that returns hot-list-like items.
- Any generic RSS/Atom URL.
- Manual text imports from Douyin, TopHub, OceanEngine, Xiaohongshu, Weibo, or browser-copied lists.

## Install

From a clone:

```powershell
python -m pip install -e .
```

Then check:

```powershell
codex-hot-media --json doctor
codex-hot-media --json sources
codex-hot-media --json agent-guide
```

Agent integration files:

- Codex skill: `.codex/skills/codex-hot-media/SKILL.md`
- Claude Code memory: `CLAUDE.md`
- Claude Code slash command: `.claude/commands/hot-media.md`
- Shared guide: `AGENT_GUIDE.md`

## Quick Start

Run the default public Bilibili pipeline:

```powershell
codex-hot-media --json run --source bilibili --pages 2 --page-size 20 --top-n 8 --out-dir outputs
```

If Bilibili returns an anti-abuse code, reduce `--pages` / `--page-size` or switch to a self-hosted DailyHotApi/RSSHub route. The CLI uses browser-like headers but does not use cookies or login state.

This creates:

- `outputs/data/hot_items_latest.json`
- `outputs/data/hot_items_latest.md`
- `outputs/video_plan_from_hot_latest.json`
- `outputs/video_plan_from_hot_latest.md`
- `outputs/publish_pack/publish_pack_latest.json`
- `outputs/publish_pack/publish_pack_latest.md`
- `outputs/publish_pack/publish_log_template.csv`
- `outputs/dashboard.html`

## Commands

```powershell
codex-hot-media --json doctor
codex-hot-media --json sources
codex-hot-media --json agent-guide
codex-hot-media --json collect --source bilibili --pages 3 --page-size 20 --out-dir outputs/data --prefix hot_items
codex-hot-media --json plan --input outputs/data/hot_items_latest.json --top-n 10 --out-dir outputs
codex-hot-media --json pack --plan outputs/video_plan_from_hot_latest.json --out-dir outputs
codex-hot-media --json dashboard --plan outputs/video_plan_from_hot_latest.json --pack outputs/publish_pack/publish_pack_latest.json --out outputs/dashboard.html
```

Manual import:

```powershell
codex-hot-media --json import-text --input examples/manual_hot_titles.txt --source-name manual --out-dir outputs/data --prefix manual_hot
codex-hot-media --json plan --input outputs/data/manual_hot_latest.json --top-n 5 --out-dir outputs
codex-hot-media --json pack --plan outputs/video_plan_from_hot_latest.json --out-dir outputs
```

DailyHotApi self-hosted route:

```powershell
codex-hot-media --json collect --source dailyhot --base-url http://127.0.0.1:6688 --route bilibili --out-dir outputs/data --prefix dailyhot_bilibili
```

RSSHub route:

```powershell
codex-hot-media --json collect --source rss --base-url http://127.0.0.1:1200 --route bilibili/popular/all --out-dir outputs/data --prefix rsshub_bilibili
```

Generic JSON/RSS:

```powershell
codex-hot-media --json collect --source json-url --url https://example.com/hot.json --source-name custom --out-dir outputs/data --prefix custom_hot
codex-hot-media --json collect --source rss --url https://example.com/feed.xml --source-name custom-rss --out-dir outputs/data --prefix custom_rss
```

NewsNow / TrendRadar / OpenClaw-style self-hosted JSON:

```powershell
codex-hot-media --json collect --source json-url --url http://127.0.0.1:3000/api/hot --source-name newsnow --out-dir outputs/data --prefix newsnow_hot
codex-hot-media --json plan --input outputs/data/newsnow_hot_latest.json --top-n 10 --out-dir outputs
codex-hot-media --json pack --plan outputs/video_plan_from_hot_latest.json --out-dir outputs
```

## JSON Contract

Success:

```json
{
  "status": "ok",
  "action": "run",
  "collect": {},
  "plan": {},
  "pack": {},
  "dashboard_html": "outputs/dashboard.html"
}
```

Error:

```json
{
  "status": "error",
  "action": "collect",
  "message": "network or input error"
}
```

No credentials are required or printed. If you use private/self-hosted services, pass only normal URLs; do not pass cookies or account tokens to this CLI.

## Safety Boundary

This tool does:

- collect public or self-hosted hot-list data,
- normalize it into JSON/Markdown,
- generate original-content planning drafts,
- generate platform-specific manual copy packs,
- create a manual publishing log template.

This tool does not:

- log in to platforms,
- scrape behind authentication,
- copy source footage,
- upload videos,
- auto-publish posts,
- manage accounts, payments, OAuth, cookies, or tokens.

## Existing Windows MVP Scripts

The `tools/*.ps1` scripts are kept as a Windows local MVP layer. The GitHub-facing portable CLI is the Python package under `src/codex_hot_media`.

Use the PowerShell pipeline only when you want the original local demo flow:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\run_daily_hot_pipeline.ps1
```
