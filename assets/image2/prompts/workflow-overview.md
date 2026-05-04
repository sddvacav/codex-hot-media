# Image2 Prompt Record: Workflow Overview

- Project: codex-hot-media
- Intended asset: workflow overview
- Target document: README.md, AGENT_GUIDE.md, project publishing page
- Date: 2026-05-04
- Size: 1536x1024
- Quality: high
- Status: generated and stored at `assets/image2/workflow-overview.png`

## Prompt

Create a clear workflow overview graphic for a GitHub project named "codex-hot-media".

Show a left-to-right system flow:
1. public/self-hosted hot-list inputs: Bilibili, DailyHotApi, RSSHub, NewsNow, TrendRadar, OpenClaw, generic JSON/RSS, manual import
2. core CLI: codex-hot-media
3. agent entry points: Codex skill, Claude Code CLAUDE.md and slash command, optional MCP input
4. generated local artifacts: hot_items_latest.json, video_plan_from_hot_latest.md, publish_pack_latest.md, publish_log_template.csv, dashboard.html
5. final step: manual review, not auto-publish

Design style: world-class technical documentation graphic, clean spacing, readable labels, subtle grid, restrained color palette, premium GitHub README quality. Avoid decorative blobs, cartoon icons, fake screenshots, and marketing fluff.

## Manual Review Checklist

- [ ] The flow can be understood in under 10 seconds.
- [ ] All major input categories are represented.
- [ ] CLI is clearly the core.
- [ ] Codex and Claude Code are both present.
- [ ] Manual review boundary is explicit.
- [ ] The graphic supports documentation rather than decoration.

## Review Notes

- Generated with Image2 on 2026-05-04.
- Updated project source set includes AutoCLI as an optional bridge.
- Manual review still required before using it as the only architecture diagram.
