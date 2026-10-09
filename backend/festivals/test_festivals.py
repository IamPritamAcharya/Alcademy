from datetime import datetime, timezone
import io
import json
import unittest
import urllib.error
from unittest.mock import patch

from fetch import build_snapshot, parse_calendar, publish

NOW = datetime(2026, 10, 9, 8, tzinfo=timezone.utc)


def calendar(*events):
    return ('BEGIN:VCALENDAR\r\n' + ''.join(
        'BEGIN:VEVENT\r\n' + event + '\r\nEND:VEVENT\r\n' for event in events)
        + 'END:VCALENDAR\r\n').encode()


def event(date, title, extra=''):
    return f'DTSTART;VALUE=DATE:{date}\r\nSUMMARY:{title}\r\n{extra}'


class FestivalTests(unittest.TestCase):
    def test_current_next_year_only_and_folded_escaped_titles(self):
        raw = calendar(event('20251101', 'Old'), event('20261108', 'Diwali/Deepa\r\n vali'),
            event('20270101', "New Year's Day"), event('20280201', 'Later'),
            event('20261010', r'Test\, festival\; name'))
        result = build_snapshot(raw, now=NOW)
        self.assertEqual(result['years'], [2026, 2027])
        self.assertEqual(len(result['events']), 3)
        self.assertEqual(result['events'][1]['wish'], 'Happy Diwali!')
        self.assertEqual(result['events'][0]['name'], 'Test, festival; name')

    def test_ist_year_rollover_and_tentative_eid(self):
        raw = calendar(event('20270310', 'Ramzan Id (tentative)'), event('20280101', "New Year's Day"))
        result = build_snapshot(raw, now=datetime(2026, 12, 31, 19, tzinfo=timezone.utc))
        self.assertEqual(result['years'], [2027, 2028])
        self.assertTrue(result['events'][0]['tentative'])
        self.assertEqual(result['events'][0]['wish'], 'Eid Mubarak!')

    def test_no_happy_wish_for_solemn_observances_and_duplicates_removed(self):
        result = build_snapshot(calendar(event('20260403', 'Good Friday'),
            event('20261108', 'Diwali/Deepavali'), event('20261108', 'Diwali/Deepavali'),
            event('20270310', 'Ramzan Id')), now=NOW)
        self.assertNotIn('wish', result['events'][0])
        self.assertEqual(len(result['events']), 3)

    def test_incomplete_invalid_recurring_and_cancelled_calendars_fail_safely(self):
        for raw in [b'<html>Unavailable</html>', calendar(event('20261108', 'Diwali/Deepavali')),
                    calendar(event('20261301', 'Invalid'), event('20270101', 'Next')),
                    calendar(event('20261108', 'Diwali', 'RRULE:FREQ=YEARLY'), event('20270101', 'Next')),
                    calendar(event('20261108', 'Diwali', 'STATUS:CANCELLED'), event('20270101', 'Next'))]:
            with self.assertRaises(ValueError):
                build_snapshot(raw, now=NOW)

    def test_first_publish_creates_only_calendar_on_separate_orphan_branch(self):
        calls = []
        def request(url, **kwargs):
            calls.append(url)
            if '/git/ref/' in url:
                raise urllib.error.HTTPError(url, 404, 'Not Found', {}, io.BytesIO())
            if url.endswith('/git/trees'):
                self.assertEqual(json.loads(kwargs['data'])['tree'][0]['path'], 'festivals.json')
                return b'{"sha":"tree"}'
            if url.endswith('/git/commits'):
                self.assertEqual(json.loads(kwargs['data'])['parents'], [])
                return b'{"sha":"commit"}'
            self.assertEqual(json.loads(kwargs['data'])['ref'], 'refs/heads/festivals')
            return b'{}'
        with patch.dict('os.environ', {'GH_TOKEN': 'test-only', 'GITHUB_REPOSITORY': 'owner/repo'}), patch('fetch.request', side_effect=request):
            publish({'events': []})
        self.assertEqual(len(calls), 4)

    def test_existing_publish_uses_sha_and_leaves_main_untouched(self):
        def request(url, **kwargs):
            if '/git/ref/' in url: return b'{}'
            if kwargs.get('method') != 'PUT': return b'{"sha":"existing"}'
            body = json.loads(kwargs['data'])
            self.assertEqual(body['branch'], 'festivals')
            self.assertEqual(body['sha'], 'existing')
            return b'{}'
        with patch.dict('os.environ', {'GH_TOKEN': 'test-only', 'GITHUB_REPOSITORY': 'owner/repo'}), patch('fetch.request', side_effect=request):
            publish({'events': []})


if __name__ == '__main__':
    unittest.main()
