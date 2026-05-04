# Agent Guide

`codex-hot-media` is built for both Codex and Claude Code. The shared contract is the CLI, not editor-specific state.

## First Step

Every agent should start with:

```bash
codex-hot-media --json doctor
codex-hot-media --json agent-guide
```

The JSON output gives the safe command recipes, output paths, and forbidden actions.

For GitHub project construction checks, also run:

```bash
codex-hot-media --json image2-gate
```

## GitHub Project Construction Workflow

Before and during GitHub project construction, follow `docs/GITHUB_RELEASE_IMAGE2_WORKFLOW.md`. This is not only a final release step. Any README, project page, feature introduction, architecture explanation, workflow explanation, or project meaning/value section should be built with Image2 visual assets. If Image2 is unavailable, record that as a blocker instead of silently skipping the visual gate.

## Codex Integration

Codex can use:

- `.codex/skills/codex-hot-media/SKILL.md`
- `codex-hot-media --json agent-guide`

The skill should call the CLI rather than reimplement parsing, planning, or publishing-pack logic.

## Claude Code Integration

Claude Code can use:

- `CLAUDE.md`
- `.claude/commands/hot-media.md`
- `codex-hot-media --json agent-guide`

The slash command is a wrapper around the CLI. It should not add authenticated scraping, upload, or publishing behavior.

## Network Projects

The tool is designed to compose with:

- `imsyy/DailyHotApi` for self-hosted hot-list JSON routes,
- `DIYgod/RSSHub` for self-hosted RSS/Atom routes,
- `SocialSisterYi/bilibili-API-collect` as a reference for Bilibili public endpoints,
- `tophubs/TopList` and browser-visible hot-list sites as manual import sources,
- `ourongxing/newsnow` for self-hosted hot-list dashboards and exported routes,
- `ourongxing/newsnow-mcp-server` as an optional MCP input for Claude Code or other MCP-capable clients,
- `joyce677/TrendRadar` for multi-platform trend monitoring,
- `one-box-u/openclaw-daily-hot-news` for self-hosted daily hot news JSON inputs,
- NewsNow public page: `https://newsnow.busiyi.world`,
- TopHub Tech: `https://tophub.today/c/tech`,
- SoPilot hot tweets: `https://sopilot.net/zh/hot-tweets`.

## Daily 5-Minute Manual Hot Workflow

For manual daily topic review, open these three pages:

1. NewsNow for multi-platform aggregation.
2. TopHub Tech for GitHub Trending, Product Hunt, Hacker News, product and technical hotspots.
3. SoPilot for viral X posts.

Paste selected titles into a text file and run:

```bash
codex-hot-media --json import-text --input examples/manual_hot_titles.txt --source-name daily-5min --out-dir outputs/data --prefix daily_5min
codex-hot-media --json plan --input outputs/data/daily_5min_latest.json --top-n 10 --out-dir outputs
codex-hot-media --json pack --plan outputs/video_plan_from_hot_latest.json --out-dir outputs
```

See `docs/MCP_INTEGRATION.md` for the optional MCP path.

Use public/self-hosted sources as inputs. Transform them into original planning artifacts; do not copy source footage or exact creator titles.
