# Alcademy content

This directory contains all 59 files imported from the `main` branches of
`Academia-IGIT/DATA_hub` and `IamPritamAcharya/DATA_hub`.

- `Notes/`: current notes and subject lists from Academia-IGIT.
- `Blog/`, `Success stories/`, `img/`: articles, stories, and their images.
- `settings.json`: the app settings previously stored in the personal DATA_hub.
- `amenities.json`, `academic_calender.txt`, `holiday_list.txt`: campus resources.
- `legacy/iam-pritam-acharya/Notes/`: both older personal note lists, preserved
  without adding duplicate choices to the current notes directory.
- Other original JSON and image files are preserved, including data for retired
  features. Importing these files does not restore those app features.

`migration_manifest.json` records every imported path, its source commit, and
source/destination SHA-256 checksums. Destination checksums describe the import
snapshot; update the content normally afterward. Embedded source-repository image
links were rewritten to this repository. External Drive, YouTube, and social links
remain unchanged.

Edit content here, then commit and push it to `IamPritamAcharya/Alcademy` on `main`
to make it available to the app. These files are served through GitHub, rather
than bundled in the APK. Configure repository paths in
`lib/core/network/github_sources.dart`.

The original data repositories have not been deleted. Keep them available until
the consolidated content is published and existing app installations are updated.
