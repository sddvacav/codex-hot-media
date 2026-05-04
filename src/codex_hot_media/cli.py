from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from dataclasses import asdict, dataclass
from importlib import resources
from pathlib import Path
from typing import Any


USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
)


@dataclass
class HotItem:
    source: str
    title: str
    url: str = ""
    category: str = ""
    sub_category: str = ""
    author: str = ""
    view: int = 0
    like: int = 0
    coin: int = 0
    favorite: int = 0
    reply: int = 0
    share: int = 0
    duration_seconds: int = 0
    engagement_score: float = 0.0
    raw_score: float = 0.0


def utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat()


def local_stamp() -> str:
    return dt.datetime.now().strftime("%Y%m%d_%H%M%S")


def write_json(value: Any) -> None:
    print(json.dumps(value, ensure_ascii=False, indent=2))


def fail(action: str, message: str, code: int = 1) -> None:
    write_json({"status": "error", "action": action, "message": message})
    raise SystemExit(code)


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def read_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def write_json_file(path: Path, value: Any) -> None:
    ensure_dir(path.parent)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(value, handle, ensure_ascii=False, indent=2)
        handle.write("\n")


def write_text_file(path: Path, value: str) -> None:
    ensure_dir(path.parent)
    path.write_text(value, encoding="utf-8")


def file_state(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {"path": str(path), "exists": False, "length": 0, "last_write_time": None}
    stat = path.stat()
    return {
        "path": str(path),
        "exists": True,
        "length": stat.st_size,
        "last_write_time": dt.datetime.fromtimestamp(stat.st_mtime).strftime("%Y-%m-%d %H:%M:%S"),
    }


def request_bytes(url: str, timeout: int = 20) -> bytes:
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": USER_AGENT,
            "Accept": "application/json, application/rss+xml, application/atom+xml, text/xml, */*",
            "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8",
            "Referer": "https://www.bilibili.com/v/popular/all/",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return response.read()
    except urllib.error.HTTPError as exc:
        raise RuntimeError(f"HTTP {exc.code} for {url}") from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"Network error for {url}: {exc.reason}") from exc


def request_json(url: str, timeout: int = 20) -> Any:
    payload = request_bytes(url, timeout=timeout)
    return json.loads(payload.decode("utf-8", errors="replace"))


def collect_bilibili(pages: int, page_size: int, timeout: int) -> list[HotItem]:
    items: list[HotItem] = []
    for page in range(1, pages + 1):
        query = urllib.parse.urlencode({"ps": page_size, "pn": page})
        payload = request_json(f"https://api.bilibili.com/x/web-interface/popular?{query}", timeout=timeout)
        if payload.get("code") != 0:
            raise RuntimeError(f"Bilibili returned code {payload.get('code')}: {payload.get('message')}")
        for video in payload.get("data", {}).get("list", []):
            stat = video.get("stat", {}) or {}
            view = max(int(stat.get("view") or 0), 1)
            like = int(stat.get("like") or 0)
            coin = int(stat.get("coin") or 0)
            favorite = int(stat.get("favorite") or 0)
            reply = int(stat.get("reply") or 0)
            share = int(stat.get("share") or 0)
            engagement = round(((like + coin * 2 + favorite * 1.5 + reply * 1.2 + share * 1.5) / view) * 100, 2)
            bvid = str(video.get("bvid") or "")
            owner = video.get("owner", {}) or {}
            items.append(
                HotItem(
                    source="bilibili",
                    title=str(video.get("title") or "").strip(),
                    url=f"https://www.bilibili.com/video/{bvid}" if bvid else "",
                    category=str(video.get("tname") or ""),
                    sub_category=str(video.get("tnamev2") or ""),
                    author=str(owner.get("name") or ""),
                    duration_seconds=int(video.get("duration") or 0),
                    view=view,
                    like=like,
                    coin=coin,
                    favorite=favorite,
                    reply=reply,
                    share=share,
                    engagement_score=engagement,
                    raw_score=float(view),
                )
            )
    return items


def normalize_json_item(item: Any, source: str, rank: int) -> HotItem | None:
    if not isinstance(item, dict):
        return None
    title = first_text(item, ["title", "name", "word", "keyword", "desc", "hotword", "query"])
    if not title:
        return None
    url = first_text(item, ["url", "link", "href", "uri"])
    category = first_text(item, ["category", "type", "tname", "source", "label"])
    author = first_text(item, ["author", "owner", "user", "site"])
    raw_score = first_number(item, ["score", "hot", "hot_value", "heat", "views", "view", "rank"])
    engagement = raw_score if raw_score else max(1, 100 - rank)
    return HotItem(
        source=source,
        title=title,
        url=url,
        category=category,
        author=author,
        raw_score=float(raw_score or 0),
        engagement_score=round(float(engagement), 2),
    )


def first_text(item: dict[str, Any], keys: list[str]) -> str:
    for key in keys:
        value = item.get(key)
        if isinstance(value, dict):
            nested = first_text(value, keys)
            if nested:
                return nested
        if value is not None and not isinstance(value, (list, dict)):
            text = str(value).strip()
            if text:
                return text
    return ""


def first_number(item: dict[str, Any], keys: list[str]) -> float:
    for key in keys:
        value = item.get(key)
        if isinstance(value, (int, float)):
            return float(value)
        if isinstance(value, str):
            cleaned = re.sub(r"[^\d.]", "", value)
            if cleaned:
                try:
                    return float(cleaned)
                except ValueError:
                    pass
    return 0.0


def flatten_json_candidates(payload: Any) -> list[Any]:
    if isinstance(payload, list):
        return payload
    if not isinstance(payload, dict):
        return []
    candidate_keys = ["data", "list", "items", "result", "results", "cards", "topics", "hot", "news"]
    for key in candidate_keys:
        value = payload.get(key)
        if isinstance(value, list):
            return value
        if isinstance(value, dict):
            nested = flatten_json_candidates(value)
            if nested:
                return nested
    for value in payload.values():
        if isinstance(value, list) and value and isinstance(value[0], dict):
            return value
    return []


def collect_json_url(url: str, source: str, timeout: int) -> list[HotItem]:
    payload = request_json(url, timeout=timeout)
    candidates = flatten_json_candidates(payload)
    items: list[HotItem] = []
    for index, candidate in enumerate(candidates, start=1):
        normalized = normalize_json_item(candidate, source=source, rank=index)
        if normalized:
            items.append(normalized)
    return items


def collect_dailyhot(base_url: str, route: str, source: str, timeout: int) -> list[HotItem]:
    url = f"{base_url.rstrip('/')}/{route.lstrip('/')}"
    return collect_json_url(url, source=source or f"dailyhot:{route.strip('/')}", timeout=timeout)


def collect_rss(url: str, source: str, timeout: int) -> list[HotItem]:
    payload = request_bytes(url, timeout=timeout)
    root = ET.fromstring(payload)
    items: list[HotItem] = []
    namespaces = {
        "atom": "http://www.w3.org/2005/Atom",
        "rss": "http://purl.org/rss/1.0/",
    }
    rss_items = root.findall(".//item")
    if rss_items:
        for index, node in enumerate(rss_items, start=1):
            title = text_from_child(node, "title")
            link = text_from_child(node, "link")
            category = text_from_child(node, "category")
            if title:
                items.append(
                    HotItem(
                        source=source,
                        title=title,
                        url=link,
                        category=category,
                        engagement_score=max(1, 100 - index),
                    )
                )
        return items
    atom_entries = root.findall(".//atom:entry", namespaces)
    for index, node in enumerate(atom_entries, start=1):
        title = text_from_child(node, "{http://www.w3.org/2005/Atom}title")
        link_node = node.find("{http://www.w3.org/2005/Atom}link")
        link = link_node.attrib.get("href", "") if link_node is not None else ""
        if title:
            items.append(HotItem(source=source, title=title, url=link, engagement_score=max(1, 100 - index)))
    return items


def text_from_child(node: ET.Element, tag: str) -> str:
    child = node.find(tag)
    if child is None or child.text is None:
        return ""
    return child.text.strip()


def parse_manual_text(text: str, source: str) -> list[HotItem]:
    items: list[HotItem] = []
    for line in text.splitlines():
        cleaned = re.sub(r"^\s*(?:\d+|[#\-*.])[\s.、)）\]]*", "", line).strip()
        cleaned = re.sub(r"\s+", " ", cleaned)
        if len(cleaned) < 2:
            continue
        if cleaned.lower() in {"title", "hot", "rank", "榜单", "热榜"}:
            continue
        items.append(
            HotItem(
                source=source,
                title=cleaned,
                engagement_score=max(1, 100 - len(items)),
            )
        )
    return items


def write_hot_outputs(items: list[HotItem], out_dir: Path, prefix: str) -> dict[str, Any]:
    stamp = local_stamp()
    latest_json = out_dir / f"{prefix}_latest.json"
    latest_md = out_dir / f"{prefix}_latest.md"
    stamped_json = out_dir / f"{prefix}_{stamp}.json"
    stamped_md = out_dir / f"{prefix}_{stamp}.md"
    payload = [asdict(item) for item in items]
    write_json_file(stamped_json, payload)
    write_json_file(latest_json, payload)
    report = build_hot_report(items, generated_at=dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    write_text_file(stamped_md, report)
    write_text_file(latest_md, report)
    return {
        "count": len(items),
        "json": str(stamped_json),
        "markdown": str(stamped_md),
        "latest_json": str(latest_json),
        "latest_markdown": str(latest_md),
    }


def build_hot_report(items: list[HotItem], generated_at: str) -> str:
    ranked = sorted(items, key=lambda item: item.engagement_score, reverse=True)
    category_counts: dict[str, int] = {}
    for item in items:
        category = item.category or item.source
        category_counts[category] = category_counts.get(category, 0) + 1
    lines = [
        "# Hot Media Report",
        "",
        f"Generated at: {generated_at}",
        "",
        f"Total items: {len(items)}",
        "",
        "## Frequent Categories",
        "",
    ]
    for category, count in sorted(category_counts.items(), key=lambda pair: pair[1], reverse=True)[:12]:
        lines.append(f"- {category}: {count}")
    lines.extend(["", "## High Engagement Candidates", ""])
    for item in ranked[:20]:
        link = f"[{item.title}]({item.url})" if item.url else item.title
        lines.append(f"- {link} | {item.category or item.source} | score {item.engagement_score}")
    lines.extend(
        [
            "",
            "## Production Rules",
            "",
            "1. Reuse hook structure, audience tension, pacing, and topic category only.",
            "2. Replace source footage with your own demo, test, template, opinion, or screen recording.",
            "3. Do not copy exact titles, source footage, or creator-specific claims.",
            "4. Keep account login, payment links, and final publishing manual.",
        ]
    )
    return "\n".join(lines) + "\n"


def angle_for(index: int) -> str:
    angles = [
        "extract hook, conflict, and payoff, then convert it into a practical AI workflow case",
        "turn the title into a question-driven explainer for tools and knowledge products",
        "reuse the life-contrast structure for a low-budget creator diary",
        "extract review and emotional structure, then use it for product teardown content",
        "extract fandom language and contrast, then convert it into workflow storytelling",
    ]
    return angles[index % len(angles)]


def conversion_for(index: int) -> str:
    hooks = [
        "9.9 AI tool list",
        "29 media dashboard template",
        "99 account diagnosis",
        "free comment keyword collection",
        "hot report download",
    ]
    return hooks[index % len(hooks)]


def create_plans(items: list[dict[str, Any]], top_n: int) -> list[dict[str, Any]]:
    ranked = sorted(items, key=lambda item: float(item.get("engagement_score") or 0), reverse=True)[:top_n]
    plans: list[dict[str, Any]] = []
    for index, item in enumerate(ranked, start=1):
        conversion = conversion_for(index)
        plans.append(
            {
                "rank": index,
                "source": item.get("source", ""),
                "source_title": item.get("title", ""),
                "source_url": item.get("url", ""),
                "source_category": item.get("category", ""),
                "engagement_score": round(float(item.get("engagement_score") or 0), 2),
                "production_angle": angle_for(index),
                "platform_versions": ["douyin_60s", "bilibili_3min", "xiaohongshu_note"],
                "title_options": [
                    "Do not copy this hot topic. Extract the structure instead",
                    "I turned a hot-video pattern into an original AI workflow",
                    "How to reuse hot-topic structure without reusing the content",
                ],
                "opening_hook": "Do not copy trending videos. Copy the structure, then replace it with your own test and product.",
                "shot_plan": [
                    "show the hot topic title as structure reference only",
                    "mark the hook, conflict, and payoff",
                    "convert the structure into an AI media workflow",
                    "show your own template, test, dashboard, or screen recording",
                    "end with a manual CTA keyword",
                ],
                "voiceover": (
                    "This topic is useful because it has a clear hook, a strong emotional gap, and a payoff. "
                    "For our account, we do not copy the content. We extract the structure and turn it into a real workflow: "
                    "collect a trend, generate a script, make a template, and test whether users ask for it."
                ),
                "conversion": conversion,
                "risk_check": [
                    "do not reuse original footage",
                    "do not copy the exact source title",
                    "add your own screen recording, dashboard demo, product test, or opinion",
                    "avoid income guarantees",
                    "publish manually from an account you own",
                ],
            }
        )
    return plans


def write_plan_outputs(plans: list[dict[str, Any]], out_dir: Path, prefix: str = "video_plan_from_hot") -> dict[str, Any]:
    stamp = local_stamp()
    latest_json = out_dir / f"{prefix}_latest.json"
    latest_md = out_dir / f"{prefix}_latest.md"
    stamped_json = out_dir / f"{prefix}_{stamp}.json"
    stamped_md = out_dir / f"{prefix}_{stamp}.md"
    write_json_file(stamped_json, plans)
    write_json_file(latest_json, plans)
    markdown = build_plan_markdown(plans)
    write_text_file(stamped_md, markdown)
    write_text_file(latest_md, markdown)
    return {
        "count": len(plans),
        "json": str(stamped_json),
        "markdown": str(stamped_md),
        "latest_json": str(latest_json),
        "latest_markdown": str(latest_md),
    }


def build_plan_markdown(plans: list[dict[str, Any]]) -> str:
    lines = [
        "# Video Plan From Hot Trends",
        "",
        f"Generated at: {dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        "",
        "Rule: reuse trend structure, not original content.",
        "",
    ]
    for plan in plans:
        lines.extend(
            [
                f"## {plan['rank']}. {plan['source_title']}",
                "",
                f"- Source: {plan['source_url']}",
                f"- Category: {plan['source_category']}",
                f"- Engagement score: {plan['engagement_score']}",
                f"- Production angle: {plan['production_angle']}",
                f"- Opening hook: {plan['opening_hook']}",
                f"- Conversion: {plan['conversion']}",
                "",
                "Title options:",
            ]
        )
        for title in plan["title_options"]:
            lines.append(f"- {title}")
        lines.extend(["", "Shot plan:"])
        for shot in plan["shot_plan"]:
            lines.append(f"- {shot}")
        lines.extend(["", "Voiceover:", "", plan["voiceover"], "", "Risk check:"])
        for risk in plan["risk_check"]:
            lines.append(f"- {risk}")
        lines.append("")
    return "\n".join(lines)


def create_publish_pack(plans: list[dict[str, Any]]) -> list[dict[str, Any]]:
    pack: list[dict[str, Any]] = []
    for plan in plans:
        source_category = plan.get("source_category", "")
        conversion = plan.get("conversion", "")
        hook = plan.get("opening_hook", "")
        base_title = plan.get("title_options", ["Hot structure to original workflow"])[0]
        common = "Original remake plan. No source footage reused. Manual review required before publishing."
        pack.append(
            {
                "rank": plan["rank"],
                "source_title": plan.get("source_title", ""),
                "source_url": plan.get("source_url", ""),
                "source_category": source_category,
                "engagement_score": plan.get("engagement_score", 0),
                "conversion": conversion,
                "review_status": "manual_review_required",
                "platforms": {
                    "douyin": {
                        "title": "Do not copy hot videos: reuse the structure",
                        "description": (
                            f"{hook}\n\nSource category: {source_category}\n"
                            f"Angle: {plan.get('production_angle', '')}\nCTA: comment AI to get {conversion}.\n\n{common}"
                        ),
                        "tags": "#AI #selfmedia #hotstructure #workflow #knowledgeproduct",
                        "first_comment": "Keyword: AI. Send resources only after manual review.",
                    },
                    "bilibili": {
                        "title": "How I turned a hot-video structure into an AI media workflow",
                        "description": (
                            f"{base_title}\n\nThis is a teardown of hook, conflict, pacing, and payoff. "
                            "The final content should use your own dashboard demo, screen recording, or product test.\n\n"
                            f"Conversion: {conversion}\n{common}"
                        ),
                        "tags": "AI,selfmedia,hot-topic-analysis,knowledge-product,workflow",
                        "first_comment": "Download or request the checklist only after the draft passes manual review.",
                    },
                    "xiaohongshu": {
                        "title": "Hot-topic structure to original content workflow",
                        "description": (
                            "I do not reuse the hot video itself. I only extract the hook structure, then replace it with my own AI workflow demo.\n\n"
                            "1. Find the hook\n2. Convert it into a question\n3. Show the workflow\n4. Offer a small useful template\n\n"
                            f"CTA: {conversion}"
                        ),
                        "tags": "#AI自媒体 #热点选题 #内容运营 #知识产品 #低成本创业",
                        "first_comment": "Manual review note: check facts, platform rules, and original material before posting.",
                    },
                },
                "checklist": [
                    "No source footage reused",
                    "Title is not copied from the source",
                    "Facts and claims reviewed",
                    "No income guarantee",
                    "Account owner publishes manually",
                ],
            }
        )
    return pack


def write_pack_outputs(pack: list[dict[str, Any]], out_dir: Path) -> dict[str, Any]:
    latest_json = out_dir / "publish_pack_latest.json"
    latest_md = out_dir / "publish_pack_latest.md"
    log_csv = out_dir / "publish_log_template.csv"
    write_json_file(latest_json, pack)
    write_text_file(latest_md, build_pack_markdown(pack))
    ensure_dir(log_csv.parent)
    with log_csv.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "rank",
                "platform",
                "status",
                "publish_time",
                "post_url",
                "views",
                "likes",
                "comments",
                "followers_delta",
                "notes",
            ],
        )
        writer.writeheader()
        for item in pack:
            for platform in item["platforms"]:
                writer.writerow({"rank": item["rank"], "platform": platform, "status": "draft"})
    return {
        "count": len(pack),
        "publish_pack_json": str(latest_json),
        "publish_pack_markdown": str(latest_md),
        "publish_log_template": str(log_csv),
    }


def build_pack_markdown(pack: list[dict[str, Any]]) -> str:
    lines = [
        "# Publish Content Pack",
        "",
        f"Generated at: {dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        "",
        "Manual publishing only. This tool does not log in or post to platforms.",
        "",
    ]
    for item in pack:
        lines.extend(
            [
                f"## Plan {item['rank']}",
                "",
                f"- Source title: {item['source_title']}",
                f"- Source category: {item['source_category']}",
                f"- Conversion: {item['conversion']}",
                f"- Review status: {item['review_status']}",
                "",
            ]
        )
        for platform, copy in item["platforms"].items():
            lines.extend(
                [
                    f"### {platform}",
                    "",
                    f"Title: {copy['title']}",
                    "",
                    "Description:",
                    "",
                    "```text",
                    copy["description"],
                    "```",
                    "",
                    f"Tags: {copy['tags']}",
                    "",
                    f"First comment: {copy['first_comment']}",
                    "",
                ]
            )
        lines.append("Checklist:")
        for check in item["checklist"]:
            lines.append(f"- [ ] {check}")
        lines.append("")
    return "\n".join(lines)


def build_dashboard_html(plans: list[dict[str, Any]], pack: list[dict[str, Any]]) -> str:
    rows = []
    for plan in plans:
        rows.append(
            "<tr>"
            f"<td><strong>{escape_html(plan.get('source_title', ''))}</strong></td>"
            f"<td>{escape_html(plan.get('source_category', ''))}</td>"
            f"<td>{plan.get('engagement_score', '')}</td>"
            f"<td>{escape_html(plan.get('conversion', ''))}</td>"
            "</tr>"
        )
    cards = []
    for item in pack:
        cards.append(
            "<article>"
            f"<h3>Plan {item['rank']}</h3>"
            f"<p>{escape_html(item['source_title'])}</p>"
            f"<p><b>Conversion:</b> {escape_html(item['conversion'])}</p>"
            f"<p><b>Status:</b> {escape_html(item['review_status'])}</p>"
            "</article>"
        )
    return f"""<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Codex Hot Media Dashboard</title>
  <style>
    body {{ margin: 0; font-family: Arial, "Microsoft YaHei", sans-serif; background: #f6f7f9; color: #17202a; }}
    header {{ background: #fff; border-bottom: 1px solid #d9e0ea; padding: 18px 22px; }}
    main {{ padding: 16px; display: grid; gap: 16px; }}
    section {{ background: #fff; border: 1px solid #d9e0ea; border-radius: 8px; padding: 14px; box-shadow: 0 12px 30px rgba(15, 23, 42, 0.08); }}
    h1 {{ margin: 0 0 5px; font-size: 22px; letter-spacing: 0; }}
    h2 {{ margin: 0 0 12px; font-size: 16px; letter-spacing: 0; }}
    .sub {{ color: #64748b; font-size: 12px; }}
    table {{ width: 100%; border-collapse: collapse; font-size: 13px; }}
    th, td {{ text-align: left; border-bottom: 1px solid #d9e0ea; padding: 10px 8px; vertical-align: top; }}
    th {{ background: #fbfcfe; color: #64748b; }}
    .grid {{ display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; }}
    article {{ border: 1px solid #d9e0ea; border-radius: 8px; padding: 12px; background: #fbfcfe; }}
    article h3 {{ margin: 0 0 8px; font-size: 14px; }}
    article p {{ margin: 6px 0; font-size: 12px; color: #475569; line-height: 1.5; }}
    @media (max-width: 800px) {{ .grid {{ grid-template-columns: 1fr; }} }}
  </style>
</head>
<body>
  <header>
    <h1>Codex Hot Media Dashboard</h1>
    <div class="sub">Generated at {dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}. Manual publishing only.</div>
  </header>
  <main>
    <section>
      <h2>Video Plans</h2>
      <table>
        <thead><tr><th>Topic</th><th>Category</th><th>Score</th><th>Conversion</th></tr></thead>
        <tbody>{''.join(rows)}</tbody>
      </table>
    </section>
    <section>
      <h2>Publish Pack</h2>
      <div class="grid">{''.join(cards)}</div>
    </section>
  </main>
</body>
</html>
"""


def escape_html(value: str) -> str:
    return (
        str(value)
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
        .replace("'", "&#39;")
    )


def load_source_catalog() -> list[dict[str, Any]]:
    with resources.files("codex_hot_media").joinpath("source_catalog.json").open("r", encoding="utf-8") as handle:
        return json.load(handle)


def add_common_paths(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--out-dir", default="outputs", help="Output directory for generated artifacts.")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="codex-hot-media",
        description="Agent-friendly hot-list to original media planning CLI for Codex and Claude Code.",
    )
    parser.add_argument("--json", action="store_true", help="Emit machine-readable JSON. Kept for CLI convention; JSON is always emitted for commands.")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("doctor", help="Check local CLI setup and safe operating boundaries.")
    sub.add_parser("sources", help="List supported upstream/source patterns.")
    sub.add_parser("agent-guide", help="Emit operating instructions for Codex and Claude Code agents.")

    collect = sub.add_parser("collect", help="Collect hot items from public or self-hosted sources.")
    collect.add_argument("--source", choices=["bilibili", "json-url", "dailyhot", "rss"], default="bilibili")
    collect.add_argument("--url", help="URL for json-url or rss source.")
    collect.add_argument("--base-url", help="DailyHotApi or RSSHub base URL.")
    collect.add_argument("--route", help="DailyHotApi route path.")
    collect.add_argument("--source-name", default="", help="Source label stored in output items.")
    collect.add_argument("--pages", type=int, default=3)
    collect.add_argument("--page-size", type=int, default=20)
    collect.add_argument("--timeout", type=int, default=20)
    collect.add_argument("--prefix", default="hot_items")
    add_common_paths(collect)

    import_text = sub.add_parser("import-text", help="Import pasted hot-list titles from a text file.")
    import_text.add_argument("--input", required=True, help="Text file containing one title per line or copied rank lines.")
    import_text.add_argument("--source-name", default="manual")
    import_text.add_argument("--prefix", default="manual_hot")
    add_common_paths(import_text)

    plan = sub.add_parser("plan", help="Create video plans from collected hot item JSON.")
    plan.add_argument("--input", required=True)
    plan.add_argument("--top-n", type=int, default=10)
    add_common_paths(plan)

    pack = sub.add_parser("pack", help="Create manual publish copy pack from plan JSON.")
    pack.add_argument("--plan", required=True)
    add_common_paths(pack)

    dashboard = sub.add_parser("dashboard", help="Create a static HTML dashboard from plan and pack JSON.")
    dashboard.add_argument("--plan", required=True)
    dashboard.add_argument("--pack", required=True)
    dashboard.add_argument("--out", default="dashboard.html")

    run = sub.add_parser("run", help="Run collect, plan, pack, and dashboard in one command.")
    run.add_argument("--source", choices=["bilibili", "json-url", "dailyhot", "rss"], default="bilibili")
    run.add_argument("--url")
    run.add_argument("--base-url")
    run.add_argument("--route")
    run.add_argument("--source-name", default="")
    run.add_argument("--pages", type=int, default=3)
    run.add_argument("--page-size", type=int, default=20)
    run.add_argument("--timeout", type=int, default=20)
    run.add_argument("--top-n", type=int, default=10)
    add_common_paths(run)

    return parser


def command_doctor(_: argparse.Namespace) -> dict[str, Any]:
    return {
        "status": "ok",
        "action": "doctor",
        "tool": "codex-hot-media",
        "version": "0.1.0",
        "python": sys.version.split()[0],
        "auth_required": False,
        "network_used_by": ["collect", "run"],
        "write_scope": "Only the selected --out-dir and requested dashboard output path.",
        "manual_only": ["platform login", "account authorization", "payment links", "final publishing"],
        "safe_default": "Read public/self-hosted feeds and generate drafts only.",
    }


def command_sources(_: argparse.Namespace) -> dict[str, Any]:
    return {
        "status": "ok",
        "action": "sources",
        "checked_on": "2026-05-04",
        "source_catalog": load_source_catalog(),
        "upstream_refs": {
            "imsyy/DailyHotApi_head": "36c77e3bd891c11642d314cfb229bf31646704de",
            "DIYgod/RSSHub_head": "566f028aaf1813c9d05e491b9f6c67325a06e837",
            "SocialSisterYi/bilibili-API-collect_head": "4c00347d4f3494318903eeb11fb00d7b9c1f8c68",
            "tophubs/TopList_head": "44e550cf3a4bcfe2ec1adc668fa6adb8fd453f9c",
            "ourongxing/newsnow_head": "625bf04bc9ec13acd5554d241fa1683b0506027a",
            "ourongxing/newsnow-mcp-server_head": "7abcdeb90bddf5d03818c9a81ab7169d1aa7f2c1",
            "joyce677/TrendRadar_head": "7b33d53f8233b4056c4e033178f70f135f2d156a",
            "one-box-u/openclaw-daily-hot-news_head": "93aa62ab874cfb8ccd6a5d662b40a0942b685027",
        },
    }


def command_agent_guide(_: argparse.Namespace) -> dict[str, Any]:
    return {
        "status": "ok",
        "action": "agent-guide",
        "tool": "codex-hot-media",
        "purpose": "Turn public/self-hosted hot-list inputs into original media plans and manual publish packs.",
        "first_commands": [
            "codex-hot-media --json doctor",
            "codex-hot-media --json sources",
        ],
        "safe_workflows": {
            "public_bilibili_run": "codex-hot-media --json run --source bilibili --pages 2 --page-size 20 --top-n 8 --out-dir outputs",
            "manual_import": [
                "codex-hot-media --json import-text --input examples/manual_hot_titles.txt --source-name manual --out-dir outputs/data --prefix manual_hot",
                "codex-hot-media --json plan --input outputs/data/manual_hot_latest.json --top-n 5 --out-dir outputs",
                "codex-hot-media --json pack --plan outputs/video_plan_from_hot_latest.json --out-dir outputs",
            ],
            "dailyhotapi": "codex-hot-media --json collect --source dailyhot --base-url http://127.0.0.1:6688 --route bilibili --out-dir outputs/data --prefix dailyhot_bilibili",
            "rsshub": "codex-hot-media --json collect --source rss --base-url http://127.0.0.1:1200 --route bilibili/popular/all --out-dir outputs/data --prefix rsshub_bilibili",
            "newsnow_or_trendradar_json": "codex-hot-media --json collect --source json-url --url http://127.0.0.1:3000/api/hot --source-name newsnow --out-dir outputs/data --prefix newsnow_hot",
        },
        "stable_outputs": [
            "outputs/data/hot_items_latest.json",
            "outputs/data/hot_items_latest.md",
            "outputs/video_plan_from_hot_latest.json",
            "outputs/video_plan_from_hot_latest.md",
            "outputs/publish_pack/publish_pack_latest.json",
            "outputs/publish_pack/publish_pack_latest.md",
            "outputs/publish_pack/publish_log_template.csv",
            "outputs/dashboard.html",
        ],
        "do_not_do": [
            "Do not pass cookies, tokens, or account credentials.",
            "Do not automate login, upload, or final publishing.",
            "Do not copy source footage or exact creator titles.",
            "Do not create payment links or manage accounts from this CLI.",
        ],
        "agent_integrations": {
            "codex_skill": ".codex/skills/codex-hot-media/SKILL.md",
            "claude_code_memory": "CLAUDE.md",
            "claude_code_command": ".claude/commands/hot-media.md",
            "optional_mcp_notes": "docs/MCP_INTEGRATION.md",
            "github_release_image2_workflow": "docs/GITHUB_RELEASE_IMAGE2_WORKFLOW.md",
        },
        "network_projects": [
            "imsyy/DailyHotApi",
            "DIYgod/RSSHub",
            "SocialSisterYi/bilibili-API-collect",
            "tophubs/TopList",
            "ourongxing/newsnow",
            "ourongxing/newsnow-mcp-server",
            "joyce677/TrendRadar",
            "one-box-u/openclaw-daily-hot-news",
        ],
    }


def collect_from_args(args: argparse.Namespace) -> list[HotItem]:
    if args.source == "bilibili":
        return collect_bilibili(args.pages, args.page_size, args.timeout)
    if args.source == "json-url":
        if not args.url:
            raise ValueError("--url is required for json-url")
        return collect_json_url(args.url, args.source_name or "json-url", args.timeout)
    if args.source == "dailyhot":
        if not args.base_url or not args.route:
            raise ValueError("--base-url and --route are required for dailyhot")
        return collect_dailyhot(args.base_url, args.route, args.source_name, args.timeout)
    if args.source == "rss":
        url = args.url
        if not url and args.base_url and args.route:
            url = f"{args.base_url.rstrip('/')}/{args.route.lstrip('/')}"
        if not url:
            raise ValueError("--url or --base-url plus --route is required for rss")
        return collect_rss(url, args.source_name or "rss", args.timeout)
    raise ValueError(f"Unsupported source: {args.source}")


def command_collect(args: argparse.Namespace) -> dict[str, Any]:
    items = collect_from_args(args)
    result = write_hot_outputs(items, Path(args.out_dir), args.prefix)
    return {"status": "ok", "action": "collect", "source": args.source, **result}


def command_import_text(args: argparse.Namespace) -> dict[str, Any]:
    text = Path(args.input).read_text(encoding="utf-8")
    items = parse_manual_text(text, args.source_name)
    result = write_hot_outputs(items, Path(args.out_dir), args.prefix)
    return {"status": "ok", "action": "import-text", "source": args.source_name, **result}


def command_plan(args: argparse.Namespace) -> dict[str, Any]:
    items = read_json(Path(args.input))
    plans = create_plans(items, args.top_n)
    result = write_plan_outputs(plans, Path(args.out_dir))
    return {"status": "ok", "action": "plan", **result}


def command_pack(args: argparse.Namespace) -> dict[str, Any]:
    plans = read_json(Path(args.plan))
    pack = create_publish_pack(plans)
    result = write_pack_outputs(pack, Path(args.out_dir) / "publish_pack")
    return {"status": "ok", "action": "pack", **result}


def command_dashboard(args: argparse.Namespace) -> dict[str, Any]:
    plans = read_json(Path(args.plan))
    pack = read_json(Path(args.pack))
    out = Path(args.out)
    write_text_file(out, build_dashboard_html(plans, pack))
    return {"status": "ok", "action": "dashboard", "dashboard_html": str(out)}


def command_run(args: argparse.Namespace) -> dict[str, Any]:
    out_dir = Path(args.out_dir)
    items = collect_from_args(args)
    collect_result = write_hot_outputs(items, out_dir / "data", "hot_items")
    plans = create_plans([asdict(item) for item in items], args.top_n)
    plan_result = write_plan_outputs(plans, out_dir)
    pack = create_publish_pack(plans)
    pack_result = write_pack_outputs(pack, out_dir / "publish_pack")
    dashboard_path = out_dir / "dashboard.html"
    write_text_file(dashboard_path, build_dashboard_html(plans, pack))
    return {
        "status": "ok",
        "action": "run",
        "collect": collect_result,
        "plan": plan_result,
        "pack": pack_result,
        "dashboard_html": str(dashboard_path),
        "manual_only": ["platform login", "account authorization", "payment links", "final publishing"],
    }


def main(argv: list[str] | None = None) -> None:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        if args.command == "doctor":
            result = command_doctor(args)
        elif args.command == "sources":
            result = command_sources(args)
        elif args.command == "agent-guide":
            result = command_agent_guide(args)
        elif args.command == "collect":
            result = command_collect(args)
        elif args.command == "import-text":
            result = command_import_text(args)
        elif args.command == "plan":
            result = command_plan(args)
        elif args.command == "pack":
            result = command_pack(args)
        elif args.command == "dashboard":
            result = command_dashboard(args)
        elif args.command == "run":
            result = command_run(args)
        else:
            parser.error(f"unknown command: {args.command}")
            return
    except Exception as exc:
        fail(getattr(args, "command", "unknown"), str(exc))
        return
    write_json(result)


if __name__ == "__main__":
    main()
