/// Edit GitHub repositories, branches, and content locations here.
abstract final class GitHubSources {
  static const contentRepository = 'IamPritamAcharya/Alcademy';
  static const contentBranch = 'main';
  static const contentDirectory = 'content';

  static const _api =
      'https://api.github.com/repos/$contentRepository/contents/$contentDirectory';
  static const _raw =
      'https://raw.githubusercontent.com/$contentRepository/$contentBranch/$contentDirectory';

  static const settings = '$_raw/settings.json';
  static const dailyStories =
      'https://raw.githubusercontent.com/$contentRepository/daily-stories/stories.json';
  static const festivals =
      'https://raw.githubusercontent.com/$contentRepository/festivals/festivals.json';
  static const noteYears = '$_api/Notes?ref=$contentBranch';
  static const blogs = '$_raw/blogs.json';
  static const successStories = '$_raw/success-stories.json';
  static const defaultSubjects = '$_raw/Notes/All%20First%20Years.json';
  static const amenities = '$_raw/amenities.json';
  static const documents = '$_raw/documents.json';

  /// Rebase old downloaded and cached URLs without losing a selected note year.
  static String migrateLegacyLinks(String text) {
    for (final repository in [
      'Academia-IGIT/DATA_hub',
      'IamPritamAcharya/DATA_hub',
    ]) {
      for (final prefix in [
        'https://raw.githubusercontent.com/$repository/main/',
        'https://github.com/$repository/raw/main/',
        'https://github.com/$repository/raw/refs/heads/main/',
      ]) {
        final notesPrefix = repository.startsWith('IamPritamAcharya/')
            ? '$_raw/legacy/iam-pritam-acharya/Notes/'
            : '$_raw/Notes/';
        text = text.replaceAll('${prefix}Notes/', notesPrefix);
        text = text.replaceAll(prefix, '$_raw/');
      }
    }
    text = text
        .replaceAll(
          '$_raw/legacy/iam-pritam-acharya/Notes/firstyear.json',
          defaultSubjects,
        )
        .replaceAll(
          '$_raw/legacy/iam-pritam-acharya/Notes/2nd_CSE_3rdsem.json',
          '$_raw/Notes/CSE%20Sem%203.json',
        )
        .replaceAll('$_raw/firstyear.json', defaultSubjects)
        .replaceAll(
          '$_raw/Untitled%20design.png',
          '$_raw/images/stories/welcome.png',
        )
        .replaceAll('$_raw/Blog/', '$_raw/blogs/')
        .replaceAll('$_raw/Success%20stories/', '$_raw/success-stories/');
    text = text.replaceAllMapped(
      RegExp(
        '${RegExp.escape('$_raw/img/')}'
        r'([^\s)"<>\\]+)',
      ),
      (match) {
        final filename = Uri.decodeComponent(match.group(1)!);
        final dot = filename.lastIndexOf('.');
        if (dot < 0) return match.group(0)!;
        final name = filename
            .substring(0, dot)
            .toLowerCase()
            .replaceAll(RegExp('[^a-z0-9]+'), '-');
        return '$_raw/images/success-stories/$name${filename.substring(dot).toLowerCase()}';
      },
    );
    return text;
  }
}
