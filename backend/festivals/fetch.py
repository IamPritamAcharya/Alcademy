"""Bounded current/next-year festival snapshot from Google's public India ICS."""
import argparse
import base64
from datetime import datetime, timedelta, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import urllib.error
import urllib.parse
import urllib.request

ROOT = Path(__file__).parent
SOURCE = 'https://calendar.google.com/calendar/ical/en.indian%23holiday%40group.v.calendar.google.com/public/basic.ics'
IST = timezone(timedelta(hours=5, minutes=30))
MAX_RESPONSE = 2 * 1024 * 1024


def request(url, *, headers=None, data=None, method=None):
    req = urllib.request.Request(url, data=data, method=method, headers={
        'User-Agent': 'AlcademyFestivals/1.0', **(headers or {})})
    with urllib.request.urlopen(req, timeout=30) as response:
        raw = response.read(MAX_RESPONSE + 1)
    if len(raw) > MAX_RESPONSE:
        raise ValueError('Response exceeds size limit')
    return raw


def unescape(value):
    return re.sub(r'\\([nN,;\\])', lambda match: '\n' if match[1].lower() == 'n' else match[1], value)


def parse_calendar(raw, year, greetings):
    text = raw.decode('utf-8-sig')
    # ICS folds physical lines with a leading space/tab (including SUMMARY).
    text = re.sub(r'\r?\n[ \t]', '', text)
    lines = text.splitlines()
    if not lines or lines[0] != 'BEGIN:VCALENDAR' or lines[-1] != 'END:VCALENDAR':
        raise ValueError('Invalid or truncated calendar')
    events, event, seen = [], None, set()
    for line in lines:
        if line == 'BEGIN:VEVENT':
            if event is not None:
                raise ValueError('Nested event')
            event = {}
        elif line == 'END:VEVENT':
            if event is None:
                raise ValueError('Unexpected event end')
            if event.get('STATUS', ('', ''))[1] != 'CANCELLED':
                if 'RRULE' in event or 'RDATE' in event:
                    raise ValueError('Recurring holiday format requires parser update')
                params, date_text = event.get('DTSTART', ('', ''))
                if 'VALUE=DATE' not in params or not re.fullmatch(r'\d{8}', date_text):
                    raise ValueError('Expected an all-day holiday date')
                date = datetime.strptime(date_text, '%Y%m%d').date()
                if date.year in (year, year + 1):
                    title = unescape(event.get('SUMMARY', ('', ''))[1]).strip()
                    if not title or len(title) > 180:
                        raise ValueError('Invalid holiday title')
                    key = (date.isoformat(), title.casefold())
                    if key not in seen:
                        seen.add(key)
                        name = re.sub(r'\s*\(tentative\)\s*', '', title, flags=re.I).strip().casefold()
                        greeting = greetings.get(name)
                        record = {'id': hashlib.sha256('|'.join(key).encode()).hexdigest()[:20],
                                  'date': date.isoformat(), 'name': title,
                                  'tentative': 'tentative' in title.casefold()}
                        if greeting:
                            record.update(wish=greeting['wish'], priority=greeting['priority'])
                        events.append(record)
            event = None
        elif event is not None and ':' in line:
            field, value = line.split(':', 1)
            name = field.split(';', 1)[0].upper()
            event[name] = (field.upper(), value)
    if event is not None or len(events) > 400:
        raise ValueError('Invalid event count or incomplete event')
    if any(not any(item['date'].startswith(str(value)) for item in events) for value in (year, year+1)):
        raise ValueError('Calendar must cover current and next year; previous snapshot preserved')
    return sorted(events, key=lambda event: (event['date'], event['name']))


def build_snapshot(raw, *, now=None, greetings=None):
    now = now or datetime.now(timezone.utc)
    year = now.astimezone(IST).year
    greetings = greetings if greetings is not None else json.loads((ROOT / 'greetings.json').read_text())
    return {'version': 1, 'generatedAt': now.isoformat(), 'years': [year, year+1],
            'sourceUrl': SOURCE, 'events': parse_calendar(raw, year, greetings)}


def publish(snapshot):
    token, repo = os.environ['GH_TOKEN'], os.environ['GITHUB_REPOSITORY']
    branch, filename = 'festivals', 'festivals.json'
    api = f'https://api.github.com/repos/{repo}'
    headers = {'Authorization': f'Bearer {token}', 'Accept': 'application/vnd.github+json',
               'Content-Type': 'application/json', 'X-GitHub-Api-Version': '2022-11-28'}
    def github(path, body=None, method=None):
        return json.loads(request(api + path, headers=headers,
            data=json.dumps(body).encode() if body is not None else None, method=method))
    content = json.dumps(snapshot, ensure_ascii=False, indent=2)
    try:
        github(f'/git/ref/heads/{branch}')
    except urllib.error.HTTPError as error:
        if error.code != 404:
            raise
        error.close()
        tree = github('/git/trees', {'tree': [{'path': filename, 'mode': '100644',
            'type': 'blob', 'content': content}]}, 'POST')['sha']
        commit = github('/git/commits', {'message': 'Initialize festival calendar',
            'tree': tree, 'parents': []}, 'POST')['sha']
        github('/git/refs', {'ref': f'refs/heads/{branch}', 'sha': commit}, 'POST')
        return
    existing = github(f'/contents/{filename}?ref={branch}')
    github(f'/contents/{filename}', {'message': 'Refresh festival calendar', 'branch': branch,
        'sha': existing['sha'], 'content': base64.b64encode(content.encode()).decode()}, 'PUT')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--publish', action='store_true')
    parser.add_argument('--output', type=Path)
    parser.add_argument('--input', type=Path, help='Read a local ICS for testing')
    args = parser.parse_args()
    snapshot = build_snapshot(args.input.read_bytes() if args.input else request(SOURCE))
    if args.output:
        args.output.write_text(json.dumps(snapshot, ensure_ascii=False, indent=2))
    if args.publish:
        publish(snapshot)
    print(f"Ready: {len(snapshot['events'])} events for {snapshot['years']}; "
          f"{sum('wish' in event for event in snapshot['events'])} festival wishes")


if __name__ == '__main__':
    main()
