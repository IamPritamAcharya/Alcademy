"""Public notice monitor with isolated test/production state and explicit rollout gates."""

import argparse
import base64
import hashlib
import json
import os
import re
import sys
import time
from datetime import datetime, timedelta
from html.parser import HTMLParser
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urljoin, urlparse
from urllib.request import Request, urlopen
from zoneinfo import ZoneInfo

TEST_TOPIC = "alcademy_notices_test_rmx3771_v1"
PRODUCTION_TOPIC = "alcademy_college_notices_v1"
FIREBASE_PROJECT = "igit-aca-f8d86"
STATE_BRANCH = "notification-state"
STATE_PATHS = {"test": "notices-test.json", "production": "notices-production.json"}
LOCAL_CREDENTIALS = Path(__file__).resolve().parents[1] / ".secrets" / "firebase-service-account.json"
MAX_RESPONSE = 5 * 1024 * 1024
RECENT_NOTICE_LIMIT = 100


class CheckerError(Exception):
    """Operational error whose message is safe to put in public workflow logs."""


def topic_for(audience):
    if audience not in STATE_PATHS:
        raise CheckerError("Unknown notification audience")
    return TEST_TOPIC if audience == "test" else PRODUCTION_TOPIC


def require_production_enabled(audience):
    if audience == "production" and os.environ.get("NOTICE_PRODUCTION_ENABLED") != "true":
        raise CheckerError("Production sending is disabled. NOTICE_PRODUCTION_ENABLED must be explicitly enabled for rollout.")


def now():
    return datetime.now(ZoneInfo("Asia/Kolkata"))


def request_json(url, *, method="GET", data=None, headers=None):
    body = json.dumps(data).encode() if data is not None else None
    request = Request(url, data=body, method=method, headers={
        "User-Agent": "Alcademy-Notice-Checker/1.0",
        "Content-Type": "application/json", **(headers or {}),
    })
    with urlopen(request, timeout=40) as response:
        raw = response.read(MAX_RESPONSE + 1)
    if len(raw) > MAX_RESPONSE:
        raise ValueError("Response exceeds the size limit")
    return json.loads(raw)


class NoticeParser(HTMLParser):
    """Match the same notice rows and link columns as the Flutter repository."""

    def __init__(self, source):
        super().__init__(convert_charrefs=True)
        self.source = source
        self.row = None
        self.cells = []
        self.cell = None
        self.notices = []
        self.rows_found = 0

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "tr" and attrs.get("id", "").startswith("noticerow_"):
            self.row = attrs["id"]
            self.rows_found += 1
            self.cells = []
        elif self.row is not None and tag == "td":
            self.cell = {"text": [], "links": []}
        elif self.cell is not None and tag == "a":
            self.cell["links"].append(attrs.get("href", ""))
        elif self.cell is not None and tag == "br":
            self.cell["text"].append(" ")

    def handle_data(self, data):
        if self.cell is not None:
            self.cell["text"].append(data)

    def handle_endtag(self, tag):
        if tag == "td" and self.cell is not None:
            self.cells.append(self.cell)
            self.cell = None
        elif tag == "tr" and self.row is not None:
            if len(self.cells) < 3:
                raise ValueError("Incomplete notice row; refusing to change notification state")
            title = " ".join("".join(self.cells[0]["text"]).split())
            date = " ".join("".join(self.cells[1]["text"]).split())
            links = self.cells[0]["links"] + self.cells[2]["links"]
            link = next((item for item in links if item.strip() and item.strip() != "#"), "")
            # A text-only announcement is valid even without an attachment.
            link = urljoin(self.source, link.strip()) if link else self.source
            if not title or not date or urlparse(link).scheme not in ("https", "http"):
                raise ValueError("Invalid notice row; refusing to change notification state")
            # Scope the site's row ID to its year, so titles/links can be edited
            # without treating an existing notice as newly published.
            identity = urlparse(self.source).path + ":" + self.row
            notice_id = hashlib.sha256(identity.encode()).hexdigest()[:24]
            self.notices.append({"id": notice_id, "title": title, "date": date, "url": link})
            self.row = None
            self.cell = None


def parse_notices(html, source):
    parser = NoticeParser(source)
    parser.feed(html)
    parser.close()
    if parser.row is not None or not parser.rows_found or not parser.notices:
        raise ValueError("No complete notice list found; state remains unchanged")
    ids = [notice["id"] for notice in parser.notices]
    if len(ids) != len(set(ids)):
        raise ValueError("Duplicate notice IDs in source")
    return parser.notices


def fetch_notices(year):
    source = f"https://igitsarang.ac.in/notice/{year}"
    request = Request(source, headers={"User-Agent": "Alcademy-Notice-Checker/1.0"})
    for attempt in range(3):
        try:
            with urlopen(request, timeout=20) as response:
                if urlparse(response.url).hostname != "igitsarang.ac.in":
                    raise CheckerError("Notice request redirected outside the college website")
                raw = response.read(MAX_RESPONSE + 1)
            break
        except (HTTPError, URLError, TimeoutError) as error:
            if isinstance(error, HTTPError):
                error.close()
            if isinstance(error, HTTPError) and error.code not in (429, 500, 502, 503, 504):
                raise
            if attempt == 2:
                raise
            time.sleep(2 ** attempt)
    if len(raw) > MAX_RESPONSE:
        raise ValueError("Notice page exceeds the size limit")
    return parse_notices(raw.decode("utf-8"), source)


def initial_state(audience="test"):
    return {"version": 1, "topic": topic_for(audience), "years": {}, "pending": None}


def validate_state(state, audience="test"):
    if (not isinstance(state, dict) or state.get("version") != 1
            or state.get("topic") != topic_for(audience) or not isinstance(state.get("years"), dict)
            or "pending" not in state):
        raise ValueError("Invalid notification state; refusing to reset the baseline")
    for year, ids in state["years"].items():
        if not re.fullmatch(r"\d{4}", year) or not isinstance(ids, list) or not all(isinstance(i, str) for i in ids):
            raise ValueError("Invalid notice ID history")
    pending = state["pending"]
    if pending is not None:
        if (not isinstance(pending, dict) or not isinstance(pending.get("notices"), list)
                or not pending["notices"] or pending.get("year") not in state["years"]):
            raise ValueError("Invalid pending notice batch")
        for notice in pending["notices"]:
            if not isinstance(notice, dict) or not all(isinstance(notice.get(k), str) for k in ("id", "title", "date", "url")):
                raise ValueError("Invalid pending notice")
        retained = pending.get("retained_ids")
        if retained is not None:
            known = set(state["years"][pending["year"]]) | {n["id"] for n in pending["notices"]}
            if (not isinstance(retained, list) or not retained or len(retained) > RECENT_NOTICE_LIMIT
                    or not all(isinstance(i, str) and i in known for i in retained)
                    or len(retained) != len(set(retained))):
                raise ValueError("Invalid pending notice window")


class GitHubStateStore:
    """GitHub contents API with SHA checks; never overwrite concurrent changes."""

    def __init__(self, audience="test", *, allow_missing=False):
        topic_for(audience)
        self.audience = audience
        self.path = STATE_PATHS[audience]
        self.allow_missing = allow_missing
        repository = os.environ["GITHUB_REPOSITORY"]
        if not re.fullmatch(r"[\w.-]+/[\w.-]+", repository):
            raise ValueError("Invalid repository name")
        self.base = f"https://api.github.com/repos/{repository}"
        self.headers = {"Authorization": "Bearer " + os.environ["GH_TOKEN"],
                        "Accept": "application/vnd.github+json",
                        "X-GitHub-Api-Version": "2022-11-28"}
        self.sha = None
        self.branch_exists = False

    def api(self, path, **kwargs):
        return request_json(self.base + path, headers=self.headers, **kwargs)

    def load(self):
        try:
            self.api(f"/git/ref/heads/{STATE_BRANCH}")
        except HTTPError as error:
            if error.code != 404:
                raise
            error.close()
            if self.audience == "production" and not self.allow_missing:
                raise CheckerError("Production history is missing. Run production baseline before enabling checks.")
            return initial_state(self.audience)
        self.branch_exists = True
        # A missing/corrupt file on an existing state branch is an error, not
        # permission to silently forget which notices have already been sent.
        try:
            result = self.api(f"/contents/{self.path}?ref={STATE_BRANCH}")
        except HTTPError as error:
            if error.code == 404 and self.allow_missing:
                error.close()
                return initial_state(self.audience)
            raise
        self.sha = result["sha"]
        state = json.loads(base64.b64decode(result["content"]))
        validate_state(state, self.audience)
        return state

    def save(self, state):
        validate_state(state, self.audience)
        content = json.dumps(state, indent=2, ensure_ascii=False) + "\n"
        if not self.branch_exists:
            # An orphan branch holds state alone, without a second copy of app code.
            tree = self.api("/git/trees", method="POST", data={"tree": [{
                "path": self.path, "mode": "100644", "type": "blob", "content": content,
            }]})
            commit = self.api("/git/commits", method="POST", data={
                "message": f"Initialize {self.audience} notice history", "tree": tree["sha"], "parents": [],
            })
            self.api("/git/refs", method="POST", data={
                "ref": f"refs/heads/{STATE_BRANCH}", "sha": commit["sha"],
            })
            self.branch_exists = True
            self.sha = self.api(f"/contents/{self.path}?ref={STATE_BRANCH}")["sha"]
        else:
            payload = {"message": f"Update {self.audience} notice history", "branch": STATE_BRANCH,
                       "content": base64.b64encode(content.encode()).decode()}
            if self.sha is not None:
                payload["sha"] = self.sha
            result = self.api(f"/contents/{self.path}", method="PUT", data=payload)
            self.sha = result["content"]["sha"]


def batch_message(notices, *, test=False, audience="test"):
    topic_for(audience)
    count = len(notices)
    batch_id = hashlib.sha256("\n".join(sorted(n["id"] for n in notices)).encode()).hexdigest()[:24]
    title = "New college notice" if count == 1 else f"{count} new college notices"
    if test or audience == "test":
        title = "Test · " + title
    full_title = " ".join(notices[0]["title"].split())
    preview = " ".join(full_title.split()[:4])[:96].rstrip()
    if preview != full_title:
        preview += "…"
    lines = [preview]
    if count > 1:
        lines.append(f"+{count - 1} more · Tap to view all")
    else:
        lines.append("Tap to view notice")
    body = " · ".join(lines).encode()[:850].decode("utf-8", errors="ignore")
    return {"title": title, "body": body, "data": {
        "type": "college_notice", "route": "/notice", "batch_id": batch_id,
        "notice_count": str(count), "test": "true" if audience == "test" else "false",
    }}


class FirebaseSender:
    def __init__(self, audience="test"):
        self.audience = audience
        topic_for(audience)
        import firebase_admin
        from firebase_admin import credentials, messaging
        self.messaging = messaging
        # Actions uses its secret; local development uses an ignored private file.
        configured_key = os.environ.get("FIREBASE_SERVICE_ACCOUNT_JSON", "").strip()
        key = json.loads(configured_key or LOCAL_CREDENTIALS.read_text())
        if key.get("project_id") != FIREBASE_PROJECT:
            raise ValueError("Firebase credential belongs to a different project")
        self.app = firebase_admin.initialize_app(credentials.Certificate(key))

    def subscribe_device(self, token):
        result = self.messaging.subscribe_to_topic([token], TEST_TOPIC, app=self.app)
        if result.failure_count:
            raise RuntimeError("Could not subscribe the test phone; verify its FCM token")
        print("Subscribed the single supplied device to the test-only topic.")

    def send(self, notices, *, test=False, dry_run=False):
        audience = getattr(self, "audience", "test")
        if not dry_run:
            require_production_enabled(audience)
        content = batch_message(notices, test=test, audience=audience)
        message = self.messaging.Message(
            topic=topic_for(audience),
            notification=self.messaging.Notification(title=content["title"], body=content["body"]),
            data=content["data"],
            android=self.messaging.AndroidConfig(
                priority="high", ttl=timedelta(days=1),
                notification=self.messaging.AndroidNotification(
                    channel_id="high_importance_channel", tag=content["data"]["batch_id"],
                ),
            ),
            apns=self.messaging.APNSConfig(payload=self.messaging.APNSPayload(
                aps=self.messaging.Aps(sound="default"),
            )),
        )
        self.messaging.send(message, app=self.app, dry_run=dry_run)
        if dry_run:
            print(f"Firebase validated the {audience} payload and credentials. Nothing delivered.")
        else:
            print(f"Firebase accepted one {audience}-topic notification for {len(notices)} notice(s).")


def check(store, fetch, send, *, year, audience="test"):
    require_production_enabled(audience)
    state = store.load()
    validate_state(state, audience)

    def save_bounded():
        # Keep at most two years of fixed-size ID windows. Pending delivery is
        # preserved even if a failed batch crosses a year boundary.
        keep = {str(year), str(year - 1)}
        if state["pending"]:
            keep.add(state["pending"]["year"])
        state["years"] = {key: ids[:RECENT_NOTICE_LIMIT]
                          for key, ids in state["years"].items() if key in keep}
        store.save(state)

    def deliver_pending():
        pending = state["pending"]
        claim = pending.get("claim_until")
        if claim is not None:
            try:
                expires = datetime.fromisoformat(claim)
                if expires.tzinfo is None:
                    raise ValueError("Missing timezone")
            except (ValueError, TypeError):
                raise CheckerError("Invalid pending delivery claim; review state before resuming")
            if expires > now():
                print("Pending delivery is claimed by another run; nothing sent.")
                return False
        # The SHA-checked state write acts as a lease. It also protects retries
        # against a local worker racing the scheduled workflow on the same batch.
        pending["claim_until"] = (now() + timedelta(minutes=10)).isoformat()
        save_bounded()
        try:
            send(pending["notices"])
        except Exception:
            # A clean failure releases the lease. A killed worker leaves it
            # intact, and a later run retries only after its expiry.
            pending.pop("claim_until", None)
            try:
                save_bounded()
            except Exception:
                pass  # Preserve the original send error; the stored lease expires.
            raise
        old_ids = state["years"][pending["year"]]
        new_ids = [n["id"] for n in pending["notices"]]
        # The outbox carries the ordered window captured when the batch was
        # discovered. Retrying therefore needs no fresh college page. Older
        # outboxes without this optional field still retain their known IDs.
        state["years"][pending["year"]] = pending.get(
            "retained_ids", list(dict.fromkeys(new_ids + old_ids)))
        state["pending"] = None
        state["last_notification_at"] = now().isoformat()
        save_bounded()
        return True

    if state["pending"]:
        if not deliver_pending():
            return
    # Only discovering NEW notices depends on the live website. A saved batch
    # has already been delivered/acknowledged above, even if this fetch fails.
    notices = fetch(year)
    if not notices:
        raise ValueError("Empty notice list; no new notices can be processed")
    year_key = str(year)
    if year_key not in state["years"]:
        if not state["years"]:
            state["years"][year_key] = [n["id"] for n in notices[:RECENT_NOTICE_LIMIT]]
            state["baseline_at"] = now().isoformat()
            save_bounded()
            print(f"Established {year} baseline ({len(notices)} notices); nothing sent.")
            return
        # At New Year, the first notices of the new year are genuinely new.
        state["years"][year_key] = []
    seen = set(state["years"][year_key])
    if seen:
        matches = [index for index, notice in enumerate(notices) if notice["id"] in seen]
        if not matches:
            raise CheckerError("No recent notice anchors match; review source before resuming. History was not reset.")
        # Scan through the oldest matching anchor, rather than stopping at the
        # first one. This catches notices inserted between existing rows.
        candidates = notices[:matches[-1] + 1]
    else:
        candidates = notices
    new = [n for n in candidates if n["id"] not in seen]
    if not new:
        # Clean up older state produced by previous checker versions, if any.
        retained_years = {str(year), str(year - 1)}
        if any(key not in retained_years or len(ids) > RECENT_NOTICE_LIMIT
               for key, ids in state["years"].items()):
            state["years"][year_key] = [n["id"] for n in notices if n["id"] in seen][:RECENT_NOTICE_LIMIT]
            save_bounded()
        print("No new notices; no notification needed.")
        return
    new_ids = [n["id"] for n in new]
    old_ids = state["years"][year_key]
    known = set(old_ids) | set(new_ids)
    # Preserve website order in the durable outbox so a retry during an outage
    # keeps the same pruning decisions as the original successful scrape.
    visible = [n["id"] for n in notices if n["id"] in known]
    visible_ids = set(visible)
    missing = list(dict.fromkeys(i for i in new_ids + old_ids if i not in visible_ids))
    state["pending"] = {"year": year_key, "notices": new,
                        "retained_ids": (visible + missing)[:RECENT_NOTICE_LIMIT]}
    # deliver_pending commits the outbox and delivery lease together before sending.
    deliver_pending()


def baseline(store, fetch, *, year, audience="test"):
    """Explicit silent initialization/recovery. Never discard an unsent outbox."""
    state = store.load()
    validate_state(state, audience)
    if state["pending"]:
        raise CheckerError("Cannot reset a baseline while a notification batch is pending")
    notices = fetch(year)
    if not notices:
        raise CheckerError("Cannot baseline an empty notice list")
    previous = state["years"].get(str(year - 1))
    state["years"] = {str(year): [n["id"] for n in notices[:RECENT_NOTICE_LIMIT]]}
    if previous:
        state["years"][str(year - 1)] = previous[:RECENT_NOTICE_LIMIT]
    state["baseline_at"] = now().isoformat()
    store.save(state)
    print(f"Saved a silent {audience} baseline ({len(notices)} current notices). Nothing sent.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=("preview", "baseline", "validate", "check", "test"), default="preview")
    parser.add_argument("--audience", choices=("test", "production"), default="test")
    parser.add_argument("--device-token-file", type=Path,
                        help="Subscribe exactly this token to the test topic before a manual test")
    args = parser.parse_args()
    if args.mode == "test" and args.audience != "test":
        parser.error("Synthetic test notifications can only be sent to the test audience")
    if args.device_token_file and args.mode != "test":
        parser.error("Device subscription is only supported in test mode")
    year = now().year
    if args.mode == "preview":
        notices = fetch_notices(year)
        print(f"Parsed {len(notices)} notices from the college website. No state changed; nothing sent.")
        print(json.dumps(batch_message(notices[:3], audience=args.audience), indent=2, ensure_ascii=False))
        return
    if args.mode == "baseline":
        baseline(GitHubStateStore(args.audience, allow_missing=True), fetch_notices,
                 year=year, audience=args.audience)
        return
    sender = None

    def send(notices):
        nonlocal sender
        if sender is None:
            sender = FirebaseSender(args.audience)
        sender.send(notices)

    if args.mode == "check":
        check(GitHubStateStore(args.audience), fetch_notices, send, year=year, audience=args.audience)
    else:
        sender = FirebaseSender(args.audience)
        if args.device_token_file:
            token = args.device_token_file.read_text().strip()
            if not token or any(c.isspace() for c in token):
                raise ValueError("Invalid test device token file")
            sender.subscribe_device(token)
        notices = [{"id": f"manual-{now().timestamp()}-{i}", "title": title,
                    "date": now().date().isoformat(), "url": "https://igitsarang.ac.in/notice/" + str(year)}
                   for i, title in enumerate(("This test reaches only the test phone.",
                                              "Multiple notices arrive as one summary."))]
        sender.send(notices, test=args.mode == "test", dry_run=args.mode == "validate")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        # SDK/HTTP exception bodies can contain credentials or tokens. Do not log them.
        if isinstance(error, CheckerError):
            detail = str(error)
        elif isinstance(error, HTTPError):
            detail = f"HTTP {error.code}. Check source availability and API permissions."
        else:
            detail = "Check credentials, source availability, and state permissions."
        print(f"Notice checker failed ({type(error).__name__}). {detail}", file=sys.stderr)
        sys.exit(1)
