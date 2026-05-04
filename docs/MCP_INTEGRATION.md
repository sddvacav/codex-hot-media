# Optional MCP Integration

`codex-hot-media` does not require MCP. The CLI is the stable shared layer for Codex, Claude Code, shell scripts, CI, and other agents.

For Claude Code or other MCP-capable clients, `ourongxing/newsnow-mcp-server` can be used as an optional upstream hot-list provider. Treat MCP as an input source only:

1. Use MCP to discover or fetch hot-list items.
2. Export the items as JSON or copied text.
3. Feed them into this tool:

```bash
codex-hot-media --json collect --source json-url --url http://127.0.0.1:3000/api/hot --source-name newsnow --out-dir outputs/data --prefix newsnow_hot
```

or:

```bash
codex-hot-media --json import-text --input copied_hot_titles.txt --source-name newsnow-mcp --out-dir outputs/data --prefix newsnow_mcp
```

Do not use MCP to bypass platform login, cookies, account restrictions, upload flows, payment links, or final publishing. This repository only creates local draft artifacts for manual review.
