# AutoCLI Integration

`codex-hot-media` includes an optional source-level bridge for `nashsu/AutoCLI`.

This bridge lets Codex and Claude Code pull read/search results from AutoCLI into the same normalized hot-list, planning, publish-pack, and dashboard workflow used by the rest of this project.

Current-source check: 2026-05-04

- `nashsu/AutoCLI` HEAD: `c0969e2c83b29a7528452b1ba555085deca8e00d`
- `nashsu/autocli-skill` HEAD: `d6ca200b5ba65b60cf68153e88b2e9efb7f0f441`
- AutoCLI license: Apache-2.0

## Install

AutoCLI is optional. The core CLI works without it.

On Windows, download the latest Windows archive from:

```text
https://github.com/nashsu/AutoCLI/releases/latest
```

Extract `autocli.exe` and put it on `PATH`.

Browser-session profiles also require:

- Chrome running,
- the AutoCLI Chrome extension installed,
- the user already logged in to the target platform in Chrome.

Do not pass cookies, tokens, or account credentials into `codex-hot-media`.

## Inspect Profiles

```powershell
codex-hot-media --json autocli-profiles
```

If AutoCLI is missing, this command still succeeds and reports `"available": false`.

## Read And Search Profiles

Public example:

```powershell
codex-hot-media --json run --source autocli --autocli-profile hackernews-top --limit 10 --top-n 5 --out-dir outputs
```

Browser-session examples:

```powershell
codex-hot-media --json collect --source autocli --autocli-profile zhihu-hot --limit 10 --out-dir outputs/data --prefix zhihu_hot
codex-hot-media --json collect --source autocli --autocli-profile weibo-hot --limit 10 --out-dir outputs/data --prefix weibo_hot
codex-hot-media --json collect --source autocli --autocli-profile xiaohongshu-search --query AI --limit 10 --out-dir outputs/data --prefix xhs_ai
codex-hot-media --json collect --source autocli --autocli-profile twitter-search --query "AI video tools" --limit 10 --out-dir outputs/data --prefix x_ai
```

Supported bridge profiles are intentionally conservative:

- `hackernews-top`
- `bilibili-hot`
- `zhihu-hot`
- `weibo-hot`
- `twitter-trending`
- `twitter-search`
- `xiaohongshu-search`
- `reddit-hot`
- `douban-movie-hot`
- `v2ex-hot`

These profiles normalize AutoCLI output into the local `HotItem` contract.

## Write Actions

Write profiles are not collection sources.

`twitter-post` exists only behind:

```powershell
codex-hot-media --json autocli-run --profile twitter-post --text "..." --allow-write-action
```

Only use this after explicit user intent and manual review. The default media-production workflow should still generate local drafts and require the account owner to publish manually.

## Safety Boundary

This integration does not vendor AutoCLI source code and does not manage browser sessions directly. It only invokes the local `autocli` executable when installed, parses the resulting JSON/table/text output, and writes local planning artifacts.

No automatic login, upload, publishing, payment, OAuth, cookie export, or token handling is added by this bridge.
