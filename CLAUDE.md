# codex-hot-media Claude Code Guide

This repository is an agent-facing CLI for Codex and Claude Code. Use the Python CLI as the source of truth:

```bash
codex-hot-media --json doctor
codex-hot-media --json agent-guide
codex-hot-media --json image2-gate
```

For GitHub project construction, publishing, or release work, also follow:

```text
docs/GITHUB_RELEASE_IMAGE2_WORKFLOW.md
```

Do not write or publish public-facing project introduction material as complete unless Image2 assets were planned, generated or intentionally carried forward, and referenced in the project workflow. This applies to README, project pages, release pages, architecture docs, feature explanations, and meaning/value sections.

## Operating Boundary

The tool only reads public or self-hosted hot-list inputs and writes local draft artifacts. Do not add account login, cookies, token handling, upload, auto-publishing, payment links, or account management.

Allowed outputs:

- normalized hot-list JSON/Markdown,
- original short-video planning drafts,
- manual publish copy packs,
- manual publish log CSV,
- static local dashboard HTML.

## Common Commands

Default public Bilibili run:

```bash
codex-hot-media --json run --source bilibili --pages 2 --page-size 20 --top-n 8 --out-dir outputs
```

Manual import from copied hot titles:

```bash
codex-hot-media --json import-text --input examples/manual_hot_titles.txt --source-name manual --out-dir outputs/data --prefix manual_hot
codex-hot-media --json plan --input outputs/data/manual_hot_latest.json --top-n 5 --out-dir outputs
codex-hot-media --json pack --plan outputs/video_plan_from_hot_latest.json --out-dir outputs
```

DailyHotApi or RSSHub:

```bash
codex-hot-media --json collect --source dailyhot --base-url http://127.0.0.1:6688 --route bilibili --out-dir outputs/data --prefix dailyhot_bilibili
codex-hot-media --json collect --source rss --base-url http://127.0.0.1:1200 --route bilibili/popular/all --out-dir outputs/data --prefix rsshub_bilibili
```

Daily 5-minute manual sources:

- NewsNow: `https://newsnow.busiyi.world`
- TopHub Tech: `https://tophub.today/c/tech`
- SoPilot hot tweets: `https://sopilot.net/zh/hot-tweets`

Use browser-visible titles as manual input:

```bash
codex-hot-media --json import-text --input examples/manual_hot_titles.txt --source-name daily-5min --out-dir outputs/data --prefix daily_5min
codex-hot-media --json plan --input outputs/data/daily_5min_latest.json --top-n 10 --out-dir outputs
codex-hot-media --json pack --plan outputs/video_plan_from_hot_latest.json --out-dir outputs
```

## Verification

Before claiming changes are complete, run:

```bash
python -m unittest discover -s tests -p "test_*.py"
codex-hot-media --json doctor
codex-hot-media --json agent-guide
```

Network smoke test, when appropriate:

```bash
codex-hot-media --json run --source bilibili --pages 1 --page-size 3 --top-n 3 --out-dir tmp_agent_smoke
```

`tmp_*`, `outputs/`, `data/`, and generated HTML are ignored by Git.
