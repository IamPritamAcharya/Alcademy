# Alcademy content

All app content is served from this directory in `IamPritamAcharya/Alcademy`.

- `Notes/`: the original 27 notes/subject JSON files. Their names and contents
  are unchanged. Each file remains a separate branch/semester selection.
- `blogs/`: blog articles in Markdown; filenames provide their display titles.
- `success-stories/`: Markdown with `name`, `image_url`, and `company` metadata.
- `images/success-stories/`: portraits with lowercase names separated by hyphens.
- `images/stories/`: images used in the home story strip.
- `settings.json`: story content and contributor credits.
- `amenities.json`: campus facilities and descriptions.
- `documents.json`: academic-calendar and holiday PDF links.

Notes, amenities, and settings remain separate because they have different data
formats and update independently. Calendar and holiday links share one document
index. Retired feature data, archived note copies, unused images, placeholder
contributor links, and the one-time import manifest have been removed. The import
snapshot is preserved in commit `78b208d`.

Keep portrait filenames lowercase with words separated by hyphens. Update both
`image_url` and Markdown image references when changing a portrait. A contributor
can have only a `name` if no real profile link is available.

Edit content here, then commit and push to `main` to make it available to the app.
These files are not bundled in the APK. Configure source locations in
`lib/core/network/github_sources.dart`; existing cached URLs are migrated on
startup. Links to older personal note files now resolve to the corresponding
current first-year or CSE semester-3 file.

The source DATA_hub repositories remain available for older app versions.
