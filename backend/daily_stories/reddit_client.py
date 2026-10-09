"""Reddit transport with optional app-only OAuth and actionable errors."""
import base64
import json
import os
from pathlib import Path
import urllib.error
import urllib.parse

SECRETS_FILE = Path(__file__).resolve().parents[1] / '.secrets' / 'reddit-api.json'


class RedditAccessError(ValueError):
    pass


def credentials():
    values = {}
    if SECRETS_FILE.exists():
        try:
            values = json.loads(SECRETS_FILE.read_text())
            if not isinstance(values, dict):
                raise ValueError()
        except (OSError, ValueError) as error:
            raise RedditAccessError('Cannot read backend/.secrets/reddit-api.json') from error
    result = {key: os.environ.get(env) or values.get(key, '') for key, env in (
        ('client_id', 'REDDIT_CLIENT_ID'), ('client_secret', 'REDDIT_CLIENT_SECRET'),
        ('username', 'REDDIT_USERNAME'),
    )}
    if any(not isinstance(value, str) for value in result.values()):
        raise RedditAccessError('Reddit credential fields must be strings')
    if bool(result['client_id']) != bool(result['client_secret']):
        raise RedditAccessError('Both REDDIT_CLIENT_ID and REDDIT_CLIENT_SECRET are required')
    return result


class RedditClient:
    def __init__(self, fetch, *, config=None):
        self.fetch = fetch
        self.config = credentials() if config is None else config
        self.authenticated = bool(self.config.get('client_id') and self.config.get('client_secret'))
        self.token = None

    @property
    def user_agent(self):
        owner = self.config.get('username', '').strip().removeprefix('u/')
        if '\n' in owner or '\r' in owner:
            raise RedditAccessError('Invalid Reddit username')
        return 'linux:alcademy.daily-stories:v1.0' + (f' (by /u/{owner})' if owner else '')

    def _request(self, url, **kwargs):
        try:
            return self.fetch(url, **kwargs)
        except urllib.error.HTTPError as error:
            status = error.code
            retry = error.headers.get('Retry-After', '') if error.headers else ''
            # Read a bounded error page only to classify it. Never log headers,
            # access tokens, credentials, or the large HTML response.
            body = error.read(200000).lower()
            error.close()
            if status == 403:
                reason = 'Reddit network security blocked this request' if b'network security' in body else 'Reddit denied this request'
                action = ('Verify API approval and hosted-network access for this OAuth app.'
                          if self.authenticated else
                          'No OAuth credentials configured; add a Reddit API client ID and secret.')
                raise RedditAccessError(f'{reason} (HTTP 403). {action}') from None
            if status == 401:
                raise RedditAccessError('Reddit authentication failed (HTTP 401); check API credentials.') from None
            if status == 429:
                raise RedditAccessError(f'Reddit rate limited this request (HTTP 429; Retry-After: {retry or "unspecified"}).') from None
            raise RedditAccessError(f'Reddit request failed (HTTP {status}).') from None

    def _access_token(self):
        if self.token is None:
            basic = base64.b64encode(
                f"{self.config['client_id']}:{self.config['client_secret']}".encode()).decode()
            raw = self._request(
                'https://www.reddit.com/api/v1/access_token', method='POST',
                data=urllib.parse.urlencode({'grant_type': 'client_credentials'}).encode(),
                headers={'Authorization': f'Basic {basic}', 'User-Agent': self.user_agent,
                         'Content-Type': 'application/x-www-form-urlencoded'},
            )
            try:
                payload = json.loads(raw)
                token = payload.get('access_token')
                if not isinstance(token, str) or not token or payload.get('token_type', '').lower() != 'bearer':
                    raise ValueError()
            except (ValueError, AttributeError) as error:
                raise RedditAccessError('Reddit did not issue a valid OAuth token; check API access.') from error
            self.token = token
        return self.token

    def listing(self, subreddit):
        headers = {'User-Agent': self.user_agent, 'Accept': 'application/json'}
        host = 'https://www.reddit.com'
        if self.authenticated:
            headers['Authorization'] = 'Bearer ' + self._access_token()
            host = 'https://oauth.reddit.com'
        return self._request(
            f'{host}/r/{subreddit}/top.json?t=day&limit=50&raw_json=1',
            headers=headers,
        )
