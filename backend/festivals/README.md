# Monthly festival wishes

Read-only public Google India holiday ICS; no API key, Google login, Python
packages, or paid hosting. Google Calendar's guides explain public iCal access
and that holiday data includes public holidays and observances:

- https://support.google.com/calendar/answer/13748345?hl=en
- https://support.google.com/calendar/answer/37083?hl=en

`fetch.py` unfolds ICS lines, decodes escaped text, reads all-day events and
retains only the current and next year in IST. Records are deduplicated and
sorted. Truncated/invalid calendars, unsupported recurrence rules and missing
year coverage fail without publishing over a good snapshot. The bounded file
has a maximum of 400 events; previous revisions remain in Git history.

All dates are retained; `greetings.json` maps selected names to appropriate wishes
and priority. Unknown/solemn observances do not automatically get a “Happy” wish.
Same-day events choose one wish by priority, then name. Tentative dates remain
flagged in the snapshot and may change when Google updates its calendar.
To add another wish or change its wording, edit `greetings.json`.

## Workflow

`Refresh festival calendar` runs on the first of every calendar month at 05:47
IST (`17 0 1 * *` UTC). The workflow must be pushed to the default branch.
GitHub can delay scheduled runs. Manual runs default to preview-only; select
`publish=true` to create/update `festivals.json` on the separate orphan `festivals`
branch using the built-in GitHub token. Main and other feed branches are unchanged.
No notification is sent.

After pushing, manually publish once to initialize the branch; later runs are
monthly. The app's URL is centralized in `GitHubSources.festivals`.

Local preview (never publishes):

```bash
python3 backend/festivals/fetch.py --output /tmp/alcademy-festivals.json
python3 -m unittest discover -s backend/festivals -p 'test_*.py'
```

## Device behavior

A single JSON snapshot and timestamps are stored in SharedPreferences. A
successful current-month fetch avoids further HTTP until midnight IST on the
first of the next month (calendar month, not 30 days). The hero evaluates the
current IST date independently of this monthly network cache. A timer updates
at midnight while active; launch/resume rechecks it after backgrounding.

A bundled real snapshot provides first-launch dates until the published feed is
available. After failed fetches or a still-unpublished current-month feed, requests
retry no sooner than six hours; dates from the prior snapshot may remain available
for up to 90 days while its year coverage is valid. Malformed responses cannot
replace cached dates. If no suitable current-day wish is available, the normal
home greeting appears. No other app data or ERP holiday list is changed.

The server stores current/next-year records only. Device cache storage replaces
one snapshot rather than appending an unbounded history. No images are fetched.

## Preview a wish on your phone

Stop the current run and launch a debug build with:

```bash
flutter run --dart-define=FESTIVAL_PREVIEW_DATE=2026-11-08
```

This shows the Diwali wish using the stored calendar. `2026-11-11` previews Bhai
Duj. The flag changes only the displayed greeting; real dates still control
fetching and cache expiry. Invalid dates fall back to the normal behavior.
Release/profile builds ignore the flag. Run without it to restore today's wish.
