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
  static const noteYears = '$_api/Notes?ref=$contentBranch';
  static const blogs = '$_api/Blog?ref=$contentBranch';
  static const successStories = '$_api/Success%20stories?ref=$contentBranch';
  static const successStoriesRaw = '$_raw/Success%20stories';
  static const defaultSubjects = '$_raw/Notes/All%20First%20Years.json';
  static const amenities = '$_raw/amenities.json';
  static const academicCalendar = '$_raw/academic_calender.txt';
  static const holidays = '$_raw/holiday_list.txt';

  static String successStory(String filename) =>
      '$successStoriesRaw/${Uri.encodeComponent(filename)}';

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
    return text;
  }
}
