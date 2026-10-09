from datetime import datetime, timezone
import json
import io
import random
import urllib.error
import unittest
from unittest.mock import patch

from feed import build_feed, parse_news, pick, publish
from news_sources import enrich, hacker_news, public_https, select_images

NOW = datetime(2026, 10, 8, 8, tzinfo=timezone.utc)


def rss(count=10, prefix='tech'):
    return ("<rss xmlns:media='http://search.yahoo.com/mrss/'><channel>" + "".join(
        f"<item><title>{prefix} News {i}</title><link>https://example.com/{prefix}/{i}</link>"
        "<pubDate>Thu, 08 Oct 2026 07:00:00 GMT</pubDate>"
        f"<media:content medium='image' url='https://example.com/{prefix}-{i}.jpg'/>"
        "<description>&lt;p&gt;A useful development.&lt;/p&gt;</description></item>"
        for i in range(count)) + "</channel></rss>").encode()


def config():
    return {'tech_count': 8, 'india_count': 8, 'news_feeds': [
        {'name': 'Tech', 'category': 'tech', 'url': 'https://example.com/tech'},
        {'name': 'India', 'category': 'india', 'url': 'https://example.com/india'}]}


class FeedTests(unittest.TestCase):
    def test_rss_retains_image_and_excerpt(self):
        story = parse_news(rss(1), 'Tech', NOW)[0]
        self.assertEqual(story['imageUrl'], 'https://example.com/tech-0.jpg')
        self.assertEqual(story['description'], 'A useful development.')
        self.assertEqual(story['type'], 'news')

    def test_old_news_and_bad_links_are_excluded(self):
        self.assertEqual(parse_news(rss().replace(b'2026', b'2025'), 'Tech', NOW), [])
        self.assertEqual(parse_news(rss().replace(b'https://', b'javascript:'), 'Tech', NOW), [])

    def test_duplicates_removed_across_sources(self):
        stories = parse_news(rss(), 'Tech', NOW)
        self.assertEqual(len(pick([stories, stories], 20, random.Random(1))), 10)

    def test_complete_feed_counts_and_shuffle(self):
        feed = build_feed(config(), fetch=lambda url: rss(prefix=url.rsplit('/', 1)[-1]),
                          validate_image=lambda _: True, now=NOW, rng=random.Random(8))
        categories = [story['category'] for story in feed['stories']]
        self.assertEqual(categories.count('tech'), 8)
        self.assertEqual(categories.count('india'), 8)
        self.assertNotEqual(categories, sorted(categories))
        self.assertTrue(all(story['imageUrl'] for story in feed['stories']))
        self.assertEqual(feed['version'], 2)
        self.assertEqual(feed['expiresAt'], '2026-10-11T08:00:00+00:00')

    def test_failed_images_preserve_previous_published_feed(self):
        with self.assertRaisesRegex(ValueError, 'previous feed preserved'):
            build_feed(config(), fetch=lambda _: rss(), validate_image=lambda _: False, now=NOW)

    def test_preview_can_be_partial_without_fabricating_images(self):
        feed = build_feed(config(), fetch=lambda _: rss(), validate_image=lambda _: False,
                          require_complete=False, now=NOW)
        self.assertEqual(feed['stories'], [])

    def test_metadata_image_relative_url_and_description(self):
        story = parse_news(rss(1), 'Tech', NOW)[0]
        story['imageUrl'] = ''
        story['description'] = ''
        enriched = enrich(story, lambda _: b'<meta property="og:image" content="/photo.jpg"><meta name="description" content="New software">')
        self.assertEqual(enriched['imageUrl'], 'https://example.com/photo.jpg')
        self.assertEqual(enriched['description'], 'New software')

    def test_missing_description_uses_metadata_even_with_rss_image(self):
        story = parse_news(rss(1), 'Tech', NOW)[0]
        story['description'] = '  '
        enriched = enrich(story, lambda _: b'<meta name="description" content="A real summary">')
        self.assertEqual(enriched['description'], 'A real summary')
        self.assertEqual(enriched['imageUrl'], story['imageUrl'])

    def test_incomplete_news_is_skipped(self):
        story = parse_news(rss(1), 'Tech', NOW)[0]
        for field in ('title', 'description'):
            incomplete = dict(story, **{field: '  '})
            self.assertEqual(select_images([incomplete], 1, lambda _: b'<html>No summary</html>', lambda _: True), [])

    def test_missing_image_is_skipped(self):
        story = parse_news(rss(1), 'Tech', NOW)[0]
        story['imageUrl'] = ''
        self.assertEqual(select_images([story], 1, lambda _: b'<html>No picture</html>', lambda _: True), [])

    def test_hn_only_current_tech_links(self):
        items = [
            {'title': 'New Python compiler', 'url': 'https://example.com/tech', 'type': 'story', 'time': NOW.timestamp()-60},
            {'title': 'Health research', 'url': 'https://example.com/health', 'type': 'story', 'time': NOW.timestamp()-60},
            {'title': 'Python deleted', 'url': 'https://example.com/deleted', 'type': 'story', 'time': NOW.timestamp()-60, 'deleted': True},
        ]
        def fetch(url):
            return json.dumps([1, 2, 3] if 'topstories' in url else items[int(url.rsplit('/', 1)[-1].split('.')[0])-1]).encode()
        selected = hacker_news(fetch, NOW)
        self.assertEqual([story['title'] for story in selected], ['New Python compiler'])

    def test_local_and_credential_urls_rejected(self):
        for url in ['https://localhost/a', 'https://127.0.0.1/a', 'https://x.local/a', 'https://user:secret@example.com/a', 'file:///tmp/a']:
            self.assertFalse(public_https(url))

    def test_first_publication_creates_orphan_branch_with_only_feed(self):
        calls = []
        def fake_request(url, **kwargs):
            calls.append((url, kwargs))
            if url.endswith('/git/ref/heads/daily-stories'):
                raise urllib.error.HTTPError(url, 404, 'Not Found', {}, io.BytesIO())
            if url.endswith('/git/trees'):
                body = json.loads(kwargs['data'])
                self.assertEqual([entry['path'] for entry in body['tree']], ['stories.json'])
                return b'{"sha":"tree"}'
            if url.endswith('/git/commits'):
                self.assertEqual(json.loads(kwargs['data'])['parents'], [])
                return b'{"sha":"commit"}'
            return b'{}'
        with patch.dict('os.environ', {'GH_TOKEN': 'test-only', 'GITHUB_REPOSITORY': 'owner/repo'}):
            with patch('feed.request', side_effect=fake_request):
                publish({'stories': []})
        self.assertEqual(len(calls), 4)

    def test_existing_feed_updated_using_sha_on_generated_branch(self):
        def fake_request(url, **kwargs):
            if '/contents/stories.json?ref=' in url:
                return b'{"sha":"previous"}'
            if kwargs.get('method') == 'PUT':
                body = json.loads(kwargs['data'])
                self.assertEqual(body['sha'], 'previous')
                self.assertEqual(body['branch'], 'daily-stories')
            return b'{}'
        with patch.dict('os.environ', {'GH_TOKEN': 'test-only', 'GITHUB_REPOSITORY': 'owner/repo'}):
            with patch('feed.request', side_effect=fake_request):
                publish({'stories': []})


if __name__ == '__main__':
    unittest.main()
