# Agent Guide

`codex-hot-media` is built for both Codex and Claude Code. The shared contract is the CLI, not editor-specific state.

## First Step

Every agent should start with:

```bash
codex-hot-media --json doctor
codex-hot-media --json agent-guide
```

The JSON output gives the safe command recipes, output paths, and forbidden actions.

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
- `tophubs/TopList` and browser-visible hot-list sites as manual import sources.

Use public/self-hosted sources as inputs. Transform them into original planning artifacts; do not copy source footage or exact creator titles.
