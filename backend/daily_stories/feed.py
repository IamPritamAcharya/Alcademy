"""Daily illustrated tech and India news. Standard library only."""
import argparse
import base64
from datetime import datetime, timedelta, timezone
from email.utils import parsedate_to_datetime
import hashlib
import html
import json
import os
from pathlib import Path
import random
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from news_sources import hacker_news, select_images, image_available, public_https

ROOT = Path(__file__).parent
MAX_RESPONSE = 2 * 1024 * 1024
USER_AGENT = "AlcademyDailyStories/1.0 (github.com/IamPritamAcharya/Alcademy)"


def request(url, *, headers=None, data=None, method=None):
    req = urllib.request.Request(url, data=data, method=method,
                                 headers={"User-Agent": USER_AGENT, **(headers or {})})
    with urllib.request.urlopen(req, timeout=25) as response:
        raw = response.read(MAX_RESPONSE + 1)
    if len(raw) > MAX_RESPONSE:
        raise ValueError("Response exceeds size limit")
    return raw


def clean(value):
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", value or ""))).strip()


def recent(value, now):
    try:
        date = parsedate_to_datetime(value)
        if date.tzinfo is None:
            date = date.replace(tzinfo=timezone.utc)
        return now - timedelta(days=3) <= date <= now + timedelta(hours=1)
    except (ValueError, TypeError, OverflowError):
        return False


def parse_news(raw, source, now, category='tech'):
    root = ET.fromstring(raw)
    stories = []
    for item in root.findall("./channel/item"):
        title, link = clean(item.findtext("title")), clean(item.findtext("link"))
        if not title or not public_https(link) or not recent(item.findtext("pubDate"), now):
            continue
        if category == 'tech' and re.search(r'\b(sale|deals|live updates|discount|percent off)\b', title, re.I):
            continue
        link = urllib.parse.urldefrag(link)[0]
        description = clean(item.findtext("description"))
        if len(description) > 280:
            description = description[:277].rsplit(" ", 1)[0] + "…"
        image = ''
        for node in item.iter():
            tag = node.tag.rsplit('}', 1)[-1].lower()
            if tag in ('content', 'thumbnail', 'enclosure'):
                url = html.unescape(node.attrib.get('url', ''))
                if public_https(url) and (node.attrib.get('medium') == 'image'
                        or node.attrib.get('type', '').startswith('image/')
                        or tag == 'thumbnail'):
                    image = url
                    break
        if not image:
            match = re.search(r'<img[^>]+src=[\"\']([^\"\']+)', item.findtext('description') or '')
            if match and public_https(html.unescape(match[1])):
                image = html.unescape(match[1])
        stories.append({
            "id": hashlib.sha256(link.encode()).hexdigest()[:20],
            "kind": "news", "type": "news", "title": title[:180],
            "category": category, "source": source, "sourceUrl": link,
            "description": description, "imageUrl": image,
        })
    return stories[:40]


def pick(groups, count, rng):
    """Spread selection across sources, deduplicating IDs, titles and image URLs."""
    groups = [list(group) for group in groups]
    for group in groups:
        rng.shuffle(group)
    rng.shuffle(groups)
    selected, seen = [], set()
    while groups and len(selected) < count:
        remaining = []
        for group in groups:
            while group:
                story = group.pop()
                keys = {story["id"], story["title"].casefold(), story.get("url", story["sourceUrl"])}
                if keys.isdisjoint(seen):
                    selected.append(story)
                    seen.update(keys)
                    break
            if group:
                remaining.append(group)
            if len(selected) >= count:
                break
        groups = remaining
    return selected


def build_feed(config, *, fetch=request, now=None, rng=None, require_complete=True,
               validate_image=image_available):
    now = now or datetime.now(timezone.utc)
    rng = rng or random.SystemRandom()
    groups = {'tech': [], 'india': []}
    for source in config["news_feeds"]:
        try:
            groups[source['category']].append(parse_news(
                fetch(source["url"]), source["name"], now, source['category']))
        except (OSError, ValueError, ET.ParseError) as error:
            print(f"News source failed: {source['name']}: {error}", file=sys.stderr)
    if config.get('hacker_news', {}).get('enabled'):
        try:
            groups['tech'].insert(0, hacker_news(fetch, now, config['hacker_news'].get('candidate_limit', 20)))
        except (OSError, ValueError) as error:
            print(f'Hacker News failed: {error}', file=sys.stderr)
    stories = []
    counts = {}
    used_urls, used_titles = set(), set()
    for category in ('tech', 'india'):
        candidates = pick(groups[category], 40, rng)
        candidates = [story for story in candidates
                      if story['sourceUrl'] not in used_urls and story['title'].casefold() not in used_titles]
        selected = select_images(candidates, config[category + '_count'], fetch, validate_image)
        stories.extend(selected)
        used_urls.update(story['sourceUrl'] for story in selected)
        used_titles.update(story['title'].casefold() for story in selected)
        counts[category] = len(selected)
    if require_complete and any(counts[key] != config[key + '_count'] for key in counts):
        raise ValueError(f"Incomplete illustrated feed ({counts['tech']} tech, {counts['india']} India); previous feed preserved")
    rng.shuffle(stories)
    return {"version": 2, "generatedAt": now.isoformat(),
            "expiresAt": (now + timedelta(days=3)).isoformat(), "stories": stories}


def publish(feed):
    """Publish a bounded JSON file on a separate branch, leaving main untouched."""
    token, repo = os.environ["GH_TOKEN"], os.environ["GITHUB_REPOSITORY"]
    branch = "daily-stories"
    headers = {"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json",
               "Content-Type": "application/json", "X-GitHub-Api-Version": "2022-11-28"}
    api = f"https://api.github.com/repos/{repo}"

    def github(path, body=None, method=None):
        return json.loads(request(api + path, headers=headers,
                                  data=json.dumps(body).encode() if body is not None else None,
                                  method=method))

    try:
        github(f"/git/ref/heads/{branch}")
    except urllib.error.HTTPError as error:
        if error.code != 404:
            raise
        error.close()
        tree = github("/git/trees", {"tree": [{"path": "stories.json", "mode": "100644",
                       "type": "blob", "content": json.dumps(feed, ensure_ascii=False, indent=2)}]},
                      "POST")["sha"]
        initial = github("/git/commits", {"message": "Initialize daily stories feed",
                         "tree": tree, "parents": []}, "POST")["sha"]
        github("/git/refs", {"ref": f"refs/heads/{branch}", "sha": initial}, "POST")
        return
    body = {"message": "Refresh daily stories", "branch": branch,
            "content": base64.b64encode(json.dumps(feed, ensure_ascii=False, indent=2).encode()).decode()}
    try:
        body["sha"] = github(f"/contents/stories.json?ref={branch}")["sha"]
    except urllib.error.HTTPError as error:
        if error.code != 404:
            raise
        error.close()
    github("/contents/stories.json", body, "PUT")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--publish", action="store_true")
    parser.add_argument("--preview", action="store_true",
                        help="Save/print available real items even if a source fails; cannot publish")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.preview and args.publish:
        parser.error("--preview cannot be combined with --publish")
    try:
        feed = build_feed(json.loads((ROOT / "sources.json").read_text()),
                          require_complete=not args.preview)
    except ValueError as error:
        parser.exit(1, f"{error}\n")
    if args.output:
        args.output.write_text(json.dumps(feed, ensure_ascii=False, indent=2))
    if args.publish:
        publish(feed)
    tech = sum(story["category"] == "tech" for story in feed["stories"])
    india = sum(story["category"] == "india" for story in feed["stories"])
    print(f"{'Preview' if args.preview else 'Ready'}: {tech} tech + {india} India news; all have validated images; generated {feed['generatedAt']}")
    if args.preview:
        for story in feed['stories']:
            print(f"  [{story['category']}] {story['title']} ({story['source']})")


if __name__ == "__main__":
    main()
