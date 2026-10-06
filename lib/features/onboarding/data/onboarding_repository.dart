import 'package:port/features/profile/data/profile_repository.dart';
import 'package:port/features/notes/data/notes_repository.dart';

class OnboardingRepository {
  static final _notes = NotesRepository();

  static Future<List<Map<String, String>>> fetchAvailableNotes() async =>
      (await _notes.getYears()).map((year) => year.toJson()).toList();

  static Future<void> saveUserPreferences({
    required String name,
    required String branch,
    required String noteUrl,
  }) async {
    await ProfileRepository.saveUserName(name);
    await ProfileRepository.saveUserBranch(branch);
    await _notes.selectYear(noteUrl);
  }

  static Future<Map<String, String?>> getUserPreferences() async {
    return {
      'userName': await ProfileRepository.getUserName(),
      'userBranch': await ProfileRepository.getUserBranch(),
      'selectedYearUrl': await _notes.getSelectedYear(),
    };
  }
}
