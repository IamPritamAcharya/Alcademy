# Daily illustrated news

**8 tech + 8 India stories**, shuffled once per successful daily run, after the
two custom stories in `content/settings.json`. No API key, pip dependency,
or Firebase notification is used.

Sources are centralized in `sources.json`:
- Hacker News official API: recent ranked tech links (article metadata supplies images).
- Hindustan Times India RSS.
- NDTV India and Trending RSS.

The fetcher reads RSS image/enclosure fields first, then Open Graph/Twitter image
metadata when needed. It checks a small image prefix and accepts JPEG, PNG, WebP,
or GIF signatures. It skips inaccessible/image-less candidates rather than inventing
images. Missing excerpts are filled from article metadata when available; stories
without a title or description are skipped. Publisher links, names and excerpts accompany every item. HN supplies
ranking/discovery, not article content or photo rights. Check publisher reuse terms
before public rollout; public feed/image availability is not a redistribution license.

Requests are bounded: recent articles (three days), at most 60 HN candidates, up to
40 candidates per category, six concurrent workers for metadata/image validation,
25-second text and 12-second image timeouts. Failed/incomplete runs preserve the
previous published feed. Publisher URLs may still stop working after validation.

## Test and preview

```sh
python3 -m unittest discover -s backend/daily_stories -p 'test_*.py'
python3 backend/daily_stories/feed.py --output /tmp/alcademy-news.json
```

The default command requires all 16 illustrated items. To inspect available real
items even if some sources fail, use `--preview`; it cannot be combined with
`--publish`.

## Preview on your phone before pushing

```sh
python3 backend/daily_stories/feed.py --preview --output assets/data/stories-preview.json
flutter run --dart-define=LOCAL_STORIES_PREVIEW=true
```

Stop the previous Flutter session first. The compile-time flag requires a new
launch. Debug preview loads local custom settings and the real fetched snapshot,
bypassing remote story configuration. It does not overwrite production preferences.
The snapshot stays visible regardless of age for UI testing. Release/profile builds
cannot enable this mode. Launch without the flag to return to GitHub content.

## GitHub Actions

After pushing to the default branch, `Refresh daily stories` runs around 07:43
Asia/Kolkata daily. Manual runs default to fetching only; choose `publish=true`
for publication. The built-in GitHub token needs `contents: write`.

Success updates `stories.json` on the separate orphan `daily-stories` branch;
main and custom stories are untouched. The current file is bounded at 16 stories,
though earlier revisions remain in Git history. Concurrency prevents overlapping
publications. No external publication is performed by local preview commands.

Feed schema version 2 uses `type: news`, `category`, `imageUrl`, `title`,
`description`, `source`, and `sourceUrl`. The app rejects malformed/image-less
feeds and skips news without a title or description, including cached items. It
stores one news snapshot per device until the next 10:00 AM Asia/Kolkata boundary.
It refreshes on launch/resume or at that boundary while open, with a 15-minute retry
when fetching fails. A successful cache prevents repeat network requests until reset.
Old device snapshots are removed at reset; the server feed also has a three-day
freshness limit to reject an abandoned feed. The debug local preview bypasses this policy. It loads thumbnails lazily with bounded decode sizes
and preloads only the next story image. News uses a dedicated illustrated viewer
with patterned backgrounds, a fixed top source link and text sized to fit one screen;
manual text/image/video stories keep their existing viewer behavior.
