"""RSS and Hacker News adapters, article metadata, and bounded image checks."""
from concurrent.futures import ThreadPoolExecutor
from datetime import timedelta
from html.parser import HTMLParser
import html
import ipaddress
import json
import re
import urllib.parse
import urllib.request

HN_API = 'https://hacker-news.firebaseio.com/v0'
TECH_TOPIC = re.compile(
    r'\b(ai|llm|software|hardware|programming|code|coding|developer|computer|computing|'
    r'linux|windows|apple|google|microsoft|nvidia|openai|anthropic|robot|robotics|chip|'
    r'cpu|gpu|internet|browser|database|data|cyber|cybernetics|security|encryption|'
    r'python|javascript|rust|github|android|iphone|smartphone|cloud|api|dvd|startup|'
    r'tech|technology|network|compiler|quantum|semiconductor)\b', re.I)


def public_https(url):
    try:
        parsed = urllib.parse.urlsplit(url)
        host = parsed.hostname
        if parsed.scheme != 'https' or not host or parsed.username or parsed.password:
            return False
        if host == 'localhost' or host.endswith(('.localhost', '.local', '.internal')):
            return False
        try:
            ipaddress.ip_address(host)
            return False
        except ValueError:
            return True
    except ValueError:
        return False


class ArticleMetadata(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.image = ''
        self.description = ''

    def handle_starttag(self, tag, attrs):
        if tag != 'meta':
            return
        fields = dict(attrs)
        name = (fields.get('property') or fields.get('name') or '').lower()
        value = fields.get('content') or ''
        if name in ('og:image', 'og:image:secure_url', 'twitter:image') and not self.image:
            self.image = value
        if name in ('og:description', 'description', 'twitter:description') and not self.description:
            self.description = value


def enrich(story, fetch):
    result = dict(story)
    if not result.get('title', '').strip():
        raise ValueError('Article has no title')
    if not result.get('imageUrl') or not result.get('description', '').strip():
        parser = ArticleMetadata()
        parser.feed(fetch(result['sourceUrl']).decode('utf-8', errors='replace'))
        image = urllib.parse.urljoin(result['sourceUrl'], html.unescape(parser.image)) if parser.image else ''
        if not result.get('imageUrl') and public_https(image):
            result['imageUrl'] = image
        if not result.get('description', '').strip():
            result['description'] = ' '.join(html.unescape(parser.description).split())[:280]
    if not result.get('description', '').strip():
        raise ValueError('Article has no description')
    if not public_https(result.get('imageUrl', '')):
        raise ValueError('Article has no usable HTTPS image')
    return result


def image_available(url):
    if not public_https(url):
        return False
    try:
        request = urllib.request.Request(url, headers={
            'User-Agent': 'AlcademyDailyStories/1.0', 'Range': 'bytes=0-511',
        })
        with urllib.request.urlopen(request, timeout=12) as response:
            if not public_https(response.geturl()):
                return False
            raw = response.read(512)
        return (raw.startswith(b'\xff\xd8\xff') or raw.startswith(b'\x89PNG\r\n\x1a\n')
                or raw.startswith((b'GIF87a', b'GIF89a'))
                or raw.startswith(b'RIFF') and raw[8:12] == b'WEBP')
    except (OSError, ValueError):
        return False


def hacker_news(fetch, now, limit=20):
    ids = json.loads(fetch(f'{HN_API}/topstories.json'))[:min(limit, 60)]
    def item(item_id):
        try:
            story = json.loads(fetch(f'{HN_API}/item/{int(item_id)}.json'))
            if not story or story.get('type') != 'story' or story.get('dead') or story.get('deleted'):
                return None
            url = story.get('url', '')
            if not public_https(url) or not story.get('title'):
                return None
            if not TECH_TOPIC.search(story['title']):
                return None
            timestamp = story.get('time', 0)
            if not now.timestamp() - timedelta(days=3).total_seconds() <= timestamp <= now.timestamp():
                return None
            return {'id': f'hn-{item_id}', 'kind': 'news', 'type': 'news',
                    'category': 'tech', 'title': html.unescape(story['title'])[:180],
                    'source': urllib.parse.urlsplit(url).hostname.removeprefix('www.'),
                    'sourceUrl': url, 'description': '',
                    'discussionUrl': f'https://news.ycombinator.com/item?id={item_id}'}
        except (OSError, ValueError, TypeError):
            return None
    with ThreadPoolExecutor(max_workers=6) as pool:
        return [story for story in pool.map(item, ids) if story]


def select_images(candidates, count, fetch, validate=image_available):
    """Stop after enough validated stories; don't download full image files."""
    chosen = []
    def check(story):
        try:
            enriched = enrich(story, fetch)
            return enriched if validate(enriched['imageUrl']) else None
        except (OSError, ValueError):
            return None
    with ThreadPoolExecutor(max_workers=6) as pool:
        for start in range(0, len(candidates), 6):
            for story in pool.map(check, candidates[start:start + 6]):
                if story:
                    chosen.append(story)
                    if len(chosen) == count:
                        return chosen
    return chosen
