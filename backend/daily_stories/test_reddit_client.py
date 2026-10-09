import base64
import io
import json
import unittest
from urllib.error import HTTPError

from reddit_client import RedditClient, RedditAccessError


class RedditClientTests(unittest.TestCase):
    def test_public_mode_does_not_invent_credentials(self):
        calls = []
        def fetch(url, **kwargs):
            calls.append((url, kwargs))
            return b'{"data":{"children":[]}}'
        client = RedditClient(fetch, config={})
        client.listing('memes')
        self.assertFalse(client.authenticated)
        self.assertTrue(calls[0][0].startswith('https://www.reddit.com/r/'))
        self.assertNotIn('Authorization', calls[0][1]['headers'])

    def test_oauth_token_requested_once_and_reused_on_official_api(self):
        calls = []
        def fetch(url, **kwargs):
            calls.append((url, kwargs))
            if url.endswith('/access_token'):
                self.assertEqual(kwargs['data'], b'grant_type=client_credentials')
                basic = kwargs['headers']['Authorization'].removeprefix('Basic ')
                self.assertEqual(base64.b64decode(basic), b'client:secret')
                return b'{"access_token":"token","token_type":"bearer"}'
            self.assertTrue(url.startswith('https://oauth.reddit.com/r/'))
            self.assertEqual(kwargs['headers']['Authorization'], 'Bearer token')
            return b'{"data":{"children":[]}}'
        client = RedditClient(fetch, config={'client_id': 'client', 'client_secret': 'secret', 'username': 'student'})
        client.listing('memes')
        client.listing('EngineeringMemes')
        self.assertEqual(len(calls), 3)
        self.assertIn('by /u/student', calls[-1][1]['headers']['User-Agent'])

    def test_network_block_has_actionable_message(self):
        def fetch(url, **kwargs):
            raise HTTPError(url, 403, 'Forbidden', {}, io.BytesIO(b"You've been blocked by network security."))
        with self.assertRaisesRegex(RedditAccessError, 'network security.*No OAuth credentials'):
            RedditClient(fetch, config={}).listing('memes')

    def test_invalid_credentials_do_not_fall_back_to_public(self):
        calls = []
        def fetch(url, **kwargs):
            calls.append(url)
            raise HTTPError(url, 401, 'Unauthorized', {}, io.BytesIO(b'bad credentials'))
        client = RedditClient(fetch, config={'client_id': 'client', 'client_secret': 'SECRET'})
        with self.assertRaises(RedditAccessError) as raised:
            client.listing('memes')
        self.assertNotIn('SECRET', str(raised.exception))
        self.assertEqual(len(calls), 1)
        self.assertTrue(calls[0].endswith('/access_token'))

    def test_missing_token_and_rate_limit_are_explicit_failures(self):
        client = RedditClient(lambda *args, **kwargs: b'{"error":"invalid_grant"}',
                              config={'client_id': 'client', 'client_secret': 'secret'})
        with self.assertRaisesRegex(RedditAccessError, 'valid OAuth token'):
            client.listing('memes')
        def limited(url, **kwargs):
            raise HTTPError(url, 429, 'Too Many Requests', {'Retry-After': '60'}, io.BytesIO())
        with self.assertRaisesRegex(RedditAccessError, 'Retry-After: 60'):
            RedditClient(limited, config={}).listing('memes')


if __name__ == '__main__':
    unittest.main()
