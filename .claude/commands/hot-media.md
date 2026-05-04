---
description: Run the codex-hot-media agent workflow safely.
argument-hint: "[bilibili|manual|dailyhot|rss] [extra options]"
allowed-tools: Bash
---

# Hot Media Workflow

Use this command to run the repository's Codex/Claude Code media planning CLI.

First inspect the tool contract:

```bash
codex-hot-media --json doctor
codex-hot-media --json agent-guide
```

User arguments: `$ARGUMENTS`

Recommended paths:

- For a small public Bilibili smoke run:

```bash
codex-hot-media --json run --source bilibili --pages 1 --page-size 10 --top-n 5 --out-dir outputs
```

- For copied hot titles:

```bash
codex-hot-media --json import-text --input examples/manual_hot_titles.txt --source-name manual --out-dir outputs/data --prefix manual_hot
codex-hot-media --json plan --input outputs/data/manual_hot_latest.json --top-n 5 --out-dir outputs
codex-hot-media --json pack --plan outputs/video_plan_from_hot_latest.json --out-dir outputs
```

- For self-hosted DailyHotApi:

```bash
codex-hot-media --json collect --source dailyhot --base-url http://127.0.0.1:6688 --route bilibili --out-dir outputs/data --prefix dailyhot_bilibili
```

- For self-hosted RSSHub:

```bash
codex-hot-media --json collect --source rss --base-url http://127.0.0.1:1200 --route bilibili/popular/all --out-dir outputs/data --prefix rsshub_bilibili
```

Never add cookies, account tokens, login automation, upload automation, payment links, or final publishing steps. Keep all outputs local drafts for manual review.
