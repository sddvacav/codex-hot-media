---
name: codex-hot-media
description: Use this skill when Codex needs to collect public or self-hosted hot-list data, import copied trend titles, generate original short-video plans, or create manual publish packs with the codex-hot-media CLI. Triggers include hot media planning, Bilibili hot collection, DailyHotApi, RSSHub, TopHub/Douyin manual imports, AI self-media content packs, and Codex-readable JSON media pipeline tasks.
---

# Codex Hot Media

Use the `codex-hot-media` CLI. It is read/draft oriented: it collects public or self-hosted hot-list inputs and generates planning artifacts. It does not log in, upload, publish, manage accounts, or handle payment links.

## First Commands

Verify the command:

```powershell
codex-hot-media --json doctor
codex-hot-media --json sources
codex-hot-media --json agent-guide
```

For GitHub publishing or release work, read and follow `docs/GITHUB_RELEASE_IMAGE2_WORKFLOW.md`. Public releases should use Image2 visual assets before tagging or announcing the project.

Use `doctor` before any run. If it fails, inspect install state with:

```powershell
python -m pip install -e .
```

## Common Workflows

Default Bilibili public run:

```powershell
codex-hot-media --json run --source bilibili --pages 2 --page-size 20 --top-n 8 --out-dir outputs
```

Manual import from copied hot titles:

```powershell
codex-hot-media --json import-text --input examples/manual_hot_titles.txt --source-name manual --out-dir outputs/data --prefix manual_hot
codex-hot-media --json plan --input outputs/data/manual_hot_latest.json --top-n 5 --out-dir outputs
codex-hot-media --json pack --plan outputs/video_plan_from_hot_latest.json --out-dir outputs
```

Self-hosted DailyHotApi or RSSHub:

```powershell
codex-hot-media --json collect --source dailyhot --base-url http://127.0.0.1:6688 --route bilibili --out-dir outputs/data --prefix dailyhot_bilibili
codex-hot-media --json collect --source rss --base-url http://127.0.0.1:1200 --route bilibili/popular/all --out-dir outputs/data --prefix rsshub_bilibili
```

## Output Files

Look for these stable paths after `run`:

- `outputs/data/hot_items_latest.json`
- `outputs/data/hot_items_latest.md`
- `outputs/video_plan_from_hot_latest.json`
- `outputs/video_plan_from_hot_latest.md`
- `outputs/publish_pack/publish_pack_latest.json`
- `outputs/publish_pack/publish_pack_latest.md`
- `outputs/publish_pack/publish_log_template.csv`
- `outputs/dashboard.html`

## Boundaries

Do not use this CLI for account login, authenticated scraping, source footage copying, upload, auto-publishing, payment links, token handling, or account management. Keep final publishing manual.
