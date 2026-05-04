# Daily 5-Minute Manual Hot Sites

Use these three sites for the daily manual hot-list pass:

1. NewsNow: https://newsnow.busiyi.world
   - Multi-platform aggregation in one page.
   - Useful for Zhihu, Weibo, Bilibili, Hupu, V2EX and broader Chinese web hotspots.

2. TopHub Tech: https://tophub.today/c/tech
   - Technology and product-circle hotspots.
   - Useful for GitHub Trending, Product Hunt, Hacker News and adjacent maker signals.

3. SoPilot hot tweets: https://sopilot.net/zh/hot-tweets
   - X viral post monitor.
   - Useful for early comment opportunities and public-opinion movement.

Recommended flow:

```bash
codex-hot-media --json import-text --input examples/manual_hot_titles.txt --source-name daily-5min --out-dir outputs/data --prefix daily_5min
codex-hot-media --json plan --input outputs/data/daily_5min_latest.json --top-n 10 --out-dir outputs
codex-hot-media --json pack --plan outputs/video_plan_from_hot_latest.json --out-dir outputs
```

Do not automate login, cookies, account actions, or publishing from these sites. Use them as manual source discovery pages.
