# College notice notifications

The checker reads `https://igitsarang.ac.in/notice/<current year>` every ten
minutes when scheduling is enabled. It recognizes `tr[id^="noticerow_"]`,
reads title/date from the first two cells, and uses the title or download-column
link. No student login is involved.
Notices without an attachment use the official notice-list URL as their fallback;
text-only announcements do not block the rest of the list.

Test and production are isolated:

| Audience | FCM topic | State file |
| --- | --- | --- |
| Test | `alcademy_notices_test_rmx3771_v1` | `notices-test.json` |
| Production | `alcademy_college_notices_v1` | `notices-production.json` |

Defaults are safe: no scheduled checks, test audience, no production sending,
and no automatic production subscriptions in ordinary app builds. Production
needs both a release build flag and explicit backend rollout variables.

## User notification preferences

Profile has independent **Notices** and **General** switches, saved on the
device. Both default to enabled; build flags and phone permissions still gate
subscriptions. Changes sync immediately when connected and retry on app resume
or FCM token refresh. Offline unsubscriptions take effect once Firebase receives
them; notifications already queued by the operating system may still appear.

| Category | Production topic | Debug test topic |
| --- | --- | --- |
| Notices | `alcademy_college_notices_v1` | `alcademy_notices_test_rmx3771_v1` |
| General | `alcademy_general_v1` | `alcademy_general_test_rmx3771_v1` |

The checker sends only Notices, with `data.type = college_notice`. Send manual
announcements to the **General topic**, rather than all users or individual
tokens, so the General switch controls delivery. Other message types (including
messages without a data payload) are treated as General by the app. The existing
`NOTICE_PUSH_PRODUCTION=true` build flag enables subscriptions for both production
categories; `NOTICE_PUSH_TEST=true` selects both test categories in debug builds.
These switches do not enable the backend schedule or production sending.

## Storage and delivery

- Both state files live on an orphan `notification-state` branch. Do not delete
  that branch. Production requires an explicit silent `baseline` before checks.
  Test checks can establish their first silent baseline automatically.
- Notice identities use the college's `noticerow_…` IDs, scoped to their year.
  Title/link edits and reordering do not create another notification.
- Each year's history keeps at most **100 recent IDs**, and only the current
  and previous years are retained. The JSON does not accumulate forever.
  Removed IDs remain in the window until displaced by new notices, so temporary
  removals/reappearances do not immediately cause repeat alerts.
- Checks scan down through the oldest matching saved ID. This catches new rows
  inserted between existing notices, while ignoring old rows below the window.
  If every saved anchor disappears, the checker fails without sending or
  resetting history. Review the website before establishing a fresh baseline.
  Notices inserted below the recent window cannot be detected by this strategy.
- Several notices discovered together produce **one summary push**. Every ID
  is recorded, including notices omitted from the compact notification preview.
  The body previews the first notice's first four words (up to 96 characters),
  followed by `+N more · Tap to view all`. A single notice instead shows
  `Tap to view notice`, without a remaining count. Short complete titles do
  not receive an ellipsis.
- The app notification opens Notices, where the complete list is available.
- An outbox batch is committed before sending and marked delivered afterwards.
  It includes a bounded snapshot of the ordered ID window. Saved batches retry
  **before** fetching the college page, so an outage or missing new-year page
  cannot block an existing delivery. A failed scrape still fails the run, but
  a successfully acknowledged pending batch stays acknowledged and is not resent.
  Fresh notice discovery always requires a successful, valid scrape.
- Overlapping workflow runs are serialized; state writes use GitHub SHA checks.
  Every delivery also acquires a ten-minute SHA-checked lease, including retries.
  A racing local worker leaves an actively claimed batch alone. Clean send
  failures release the lease; a killed worker's claim expires automatically.
  Retained IDs follow the website's order so late insertions do not accidentally
  cause pruned older notices to be announced again.
- No-change checks make no commits unless old history needs pruning. Public
  IDs, titles, dates and PDF links are the only notice content stored on the
  state branch. No student credentials, FCM tokens, or Firebase keys belong
  there. The JSON is bounded; Git still retains prior versions in commit history.
- A crash after Firebase accepts a message but before its acknowledgement is
  saved can repeat the push next run. Android uses the same tray tag for the
  retried batch; exact-once delivery cannot be guaranteed across GitHub and FCM.
- New-year checks switch to the new year's page without resending old-year IDs.
  Source IDs must remain stable; a college website redesign requires review.
- Transient college connection errors/HTTP 429/5xx retry up to three times.
  Firebase send failures leave the durable batch for the next workflow run.
- Workflow failure logs give safe diagnostics without printing service-account
  keys, FCM tokens, or raw SDK error responses.

## Capacity and operational limits

At 2,000+ users, the checker still performs one college-page fetch per run and
one FCM topic send per discovered batch. FCM distributes the notification; no
per-user token database or per-device backend request is needed. Topic
subscriptions are not capped at 2,000 users (the 2,000 limit in Firebase docs
is topics *per app instance*). This design is suitable for public college news.

GitHub's free scheduler is best-effort: runs can be delayed or dropped, and
public-repository schedules can disable after 60 days without activity. Enable
GitHub Actions failure notifications for the maintainer, review workflow health,
and re-enable a disabled schedule. This architecture cannot promise 24/7 uptime
or exactly-once/immediate delivery. Android force-stop, disabled permissions,
offline phones, and operating-system restrictions also affect delivery.

One workflow run is serialized against others for both audiences. Prefer
workflow dispatch over local `check` runs while scheduling is active. Local
workers also respect the delivery lease and SHA checks, but do not share
GitHub's workflow queue. No lease can prevent duplicates if a sender remains
stalled past the lease expiry or Firebase accepts a request that later times out.

## Configure GitHub (when ready)

1. Firebase project: `igit-aca-f8d86`. Enable the FCM HTTP v1 API. Create a
   dedicated service account with the **Firebase Cloud Messaging API Admin**
   role. For local use, the key is stored at
   `backend/.secrets/firebase-service-account.json`. That directory is ignored
   by Git; its permissions are owner-only. Never force-add it to Git.
2. Add a repository Actions secret named `FIREBASE_SERVICE_ACCOUNT_JSON`
   containing that JSON. For a local key file:

   ```sh
   gh secret set FIREBASE_SERVICE_ACCOUNT_JSON --repo IamPritamAcharya/Alcademy < backend/.secrets/firebase-service-account.json
   ```

3. Push this workflow to the default branch. In GitHub Actions, open
   **Check college notices** with audience **test** and manually run **preview**
   first. Preview never sends or writes state. Then run **baseline** to create
   the silent baseline. Creating the state branch requires repository contents write
   permission; repository rules must allow that branch to be updated.
4. Subscribe the test phone using one of the methods below. Run **test** to send
   a clearly labelled synthetic two-notice summary, without modifying history.
5. To enable regular **test-topic-only** checks when ready:

   ```sh
   gh variable set NOTICE_CHECKER_AUDIENCE --body test --repo IamPritamAcharya/Alcademy
   gh variable set NOTICE_CHECKER_ENABLED --body true --repo IamPritamAcharya/Alcademy
   ```

   Set it to `false` to stop scheduled checking. It is disabled by default.

Firebase sends must be tested before enabling the schedule.

## Subscribe only the RMX3771

For a new debug app launch (the user runs builds):

```sh
flutter run -d 4D6PYXAM9L8P7PZX --dart-define=NOTICE_PUSH_TEST=true
```

This subscribes only that debug installation to the test topic. Release builds
ignore the test flag. A later launch without the test flag unsubscribes that
installation from the test topic. Test installations do not join production,
even if both build flags are present. Permission denial unsubscribes all topics.
Failed subscription operations retry on resume and after FCM token refresh.

Alternatively, an already-installed app's FCM registration token can be
subscribed from the backend without rebuilding. Capture only that phone's token
privately into a file outside the repository, then:

```sh
python3 -m venv /tmp/alcademy-notice-venv
/tmp/alcademy-notice-venv/bin/pip install -r backend/notice_checker/requirements.txt
# The checker loads the ignored local key automatically.
/tmp/alcademy-notice-venv/bin/python backend/notice_checker/checker.py --mode test --device-token-file /tmp/alcademy-notice-test-device-token
```

That subscribes one supplied token and sends a synthetic batch to the fixed test
topic. Never place tokens in workflow inputs, committed files, or public logs.
Test foreground, background, terminated launch, notification permission denial,
and opening Notices from the notification. Android force-stop prevents push
delivery until the user opens the app again.

## Local checks

```sh
python3 -m unittest discover -s backend/notice_checker -p 'test_*.py'
python3 backend/notice_checker/checker.py --mode preview
/tmp/alcademy-notice-venv/bin/python backend/notice_checker/checker.py --mode validate --audience production
```

The `FIREBASE_SERVICE_ACCOUNT_JSON` environment variable takes precedence over
the ignored local key, so Actions uses its repository secret. No credential
contents are printed by the checker.

Preview and unit tests need no Firebase credentials. Unit tests use synthetic
data and do not contact Firebase, GitHub, or the college website.
`validate` contacts Firebase using `dry_run=True`: it validates the payload and
credentials without delivering anything, including for the production topic.
`test` is rejected with the production audience.

## Production rollout (explicitly enabled later)

1. Push the reviewed workflow to the default branch. Run `preview` with audience
   `production`, then `validate` with audience `production`. Neither sends.
2. Run `baseline` with audience `production` immediately before rollout. It
   silently records the current recent IDs, independent of test history. It
   refuses to discard a pending delivery batch. No production sending variable
   is required for `baseline` or `validate`.
3. Build and distribute the app update with production subscriptions enabled:

   ```sh
   flutter build apk --dart-define=NOTICE_PUSH_PRODUCTION=true
   ```

   Existing app versions do not join a new topic automatically. Users must
   install the update, open it, and allow notifications. Subscriptions retry on
   subsequent resumes and token refreshes if the connection fails.
4. After rollout is authorized, enable the backend gates:

   ```sh
   gh variable set NOTICE_CHECKER_AUDIENCE --body production --repo IamPritamAcharya/Alcademy
   gh variable set NOTICE_PRODUCTION_ENABLED --body true --repo IamPritamAcharya/Alcademy
   gh variable set NOTICE_CHECKER_ENABLED --body true --repo IamPritamAcharya/Alcademy
   ```

   A manual production `check` also requires `NOTICE_PRODUCTION_ENABLED=true`.
   The sender independently enforces that gate. Never enable it merely to run
   a dry-run validation.
5. Inspect the first scheduled runs. In case of problems, set
   `NOTICE_CHECKER_ENABLED=false` to stop scheduled runs, or
   `NOTICE_PRODUCTION_ENABLED=false` to block all production sends, including
   manual checks. Keep the state files so a later restart preserves history.

For local `baseline`/`check`, the GitHub store needs `GITHUB_REPOSITORY` and
`GH_TOKEN`. Prefer workflow dispatch so the job receives its short-lived
`GITHUB_TOKEN` automatically. Never put those credentials in committed files.

References: [FCM sending](https://firebase.google.com/docs/cloud-messaging/send/admin-sdk),
[topic subscriptions](https://firebase.google.com/docs/cloud-messaging/flutter/topic-messaging),
[GitHub scheduling](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#schedule).
