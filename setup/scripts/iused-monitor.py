#!/usr/bin/env python3
"""
iused.nl MacBook monitor — scrape new listings and notify via Telegram.

Run via LaunchAgent every 30 minutes. State persisted in JSON.
Notifications sent through OpenClaw CLI (openclaw message send).

Configuration via environment (set in LaunchAgent plist):
  USED_URL          default https://www.iused.nl/refurbished/macbook/
  USED_FILTER       optional regex on title (e.g. "M[12]\\b")
  USED_MAX_PRICE    optional int (skip if above)
  TELEGRAM_TARGET   required: "telegram:<user_id>"
  STATE_FILE        default ~/.openclaw/workspace/toolbox/data/iused-state.json
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

import requests
from bs4 import BeautifulSoup


URL = os.environ.get("USED_URL", "https://www.iused.nl/refurbished/macbook/")
FILTER_PAT = os.environ.get("USED_FILTER", "")
MAX_PRICE = int(os.environ.get("USED_MAX_PRICE", "0")) or None
TELEGRAM_TARGET = os.environ.get("TELEGRAM_TARGET", "")
STATE_FILE = Path(
    os.environ.get(
        "STATE_FILE",
        str(Path.home() / ".openclaw" / "workspace" / "toolbox" / "data" / "iused-state.json"),
    )
)


def fetch_listings() -> list[dict[str, Any]]:
    r = requests.get(URL, headers={"User-Agent": "Mozilla/5.0"}, timeout=20)
    r.raise_for_status()
    soup = BeautifulSoup(r.text, "html.parser")
    items: list[dict[str, Any]] = []

    # iused.nl uses product cards — adjust selector if HTML changes
    for card in soup.select(".product-item, .product-card, article.product"):
        title_el = card.select_one(".product-title, .title, h2, h3")
        price_el = card.select_one(".price, .product-price, [class*=price]")
        link_el = card.select_one("a[href]")
        img_el = card.select_one("img")

        if not (title_el and price_el and link_el):
            continue

        title = title_el.get_text(strip=True)
        price_raw = price_el.get_text(strip=True)
        price_num = _parse_price(price_raw)
        url = link_el["href"]
        if not url.startswith("http"):
            url = "https://www.iused.nl" + url

        items.append({
            "title": title,
            "price_raw": price_raw,
            "price_eur": price_num,
            "url": url,
            "image": img_el["src"] if img_el and img_el.has_attr("src") else None,
        })

    return items


def _parse_price(s: str) -> int | None:
    m = re.search(r"(\d[\d.,]*)", s)
    if not m:
        return None
    digits = re.sub(r"[^\d]", "", m.group(1))
    return int(digits) if digits else None


def filter_listings(items: list[dict[str, Any]]) -> list[dict[str, Any]]:
    out = []
    for it in items:
        if FILTER_PAT and not re.search(FILTER_PAT, it["title"], re.I):
            continue
        if MAX_PRICE and it["price_eur"] and it["price_eur"] > MAX_PRICE:
            continue
        out.append(it)
    return out


def load_state() -> dict[str, Any]:
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text())
    return {"seen_urls": []}


def save_state(state: dict[str, Any]) -> None:
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps(state, indent=2, ensure_ascii=False))


def notify(new_items: list[dict[str, Any]]) -> None:
    if not TELEGRAM_TARGET:
        print("WARN: TELEGRAM_TARGET not set, dry-run mode", file=sys.stderr)
        for it in new_items:
            print(f"  NEW: {it['title']} — {it['price_raw']} — {it['url']}")
        return

    lines = [f"🔔 iused.nl — {len(new_items)} new listings\n"]
    for i, it in enumerate(new_items, 1):
        lines.append(f"{i}. {it['title']}")
        lines.append(f"   {it['price_raw']}")
        lines.append(f"   {it['url']}\n")

    msg = "\n".join(lines)

    subprocess.run(
        [
            "openclaw", "message", "send",
            "--channel", "telegram",
            "--target", TELEGRAM_TARGET,
            "--message", msg,
        ],
        check=False,
    )


def main() -> int:
    try:
        listings = fetch_listings()
    except Exception as e:
        print(f"ERR fetch: {e}", file=sys.stderr)
        return 1

    filtered = filter_listings(listings)
    state = load_state()
    seen = set(state.get("seen_urls", []))
    new = [it for it in filtered if it["url"] not in seen]

    if not new:
        print(f"OK: {len(listings)} total, {len(filtered)} matched, 0 new")
        return 0

    notify(new)
    state["seen_urls"] = list(seen | {it["url"] for it in new})
    save_state(state)
    print(f"OK: {len(new)} new listings, notified via {TELEGRAM_TARGET or 'dry-run'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
