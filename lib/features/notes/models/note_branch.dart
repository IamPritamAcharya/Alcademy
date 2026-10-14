import 'note_year.dart';

enum NoteBranch {
  cse('CSE', 'Computer Science', [
    'computer science',
    'computer science engineering',
  ]),
  etc('ETC', 'Electronics & Telecommunication', [
    'electronics & tc',
    'electronics & telecommunication',
  ]),
  electrical('ELEC', 'Electrical', [
    'electrical',
    'electrical engineering',
    'elec',
  ]),
  mechanical('MECH', 'Mechanical', [
    'mechanical',
    'mechanical engineering',
    'mech',
  ]),
  civil('CIVIL', 'Civil', ['civil', 'civil engineering']),
  chemical('CHEM', 'Chemical', ['chemical', 'chemical engineering', 'chem']),
  mme('MME', 'Metallurgy & Materials Engineering', [
    'metallurgical',
    'metallurgy',
    'metallurgical & materials',
    'metallurgy & materials engineering',
  ]),
  production('PROD', 'Production', ['production', 'production engineering']);

  const NoteBranch(this.code, this.label, this.aliases);
  final String code;
  final String label;
  final List<String> aliases;

  static NoteBranch? fromProfile(String? value) {
    final normalized = value?.trim().toLowerCase();
    for (final branch in values) {
      if (branch.code.toLowerCase() == normalized ||
          branch.aliases.contains(normalized)) {
        return branch;
      }
    }
    return null;
  }

  static NoteBranch? ofYear(NoteYear year) {
    final prefix = year.name.trim().split(RegExp(r'\s+')).first.toUpperCase();
    for (final branch in values) {
      if (branch.code == prefix) return branch;
    }
    return null;
  }

  static bool isCommon(NoteYear year) => RegExp(
    r'^(all\s+)?first\s+years?$',
    caseSensitive: false,
  ).hasMatch(year.name.trim());

  static List<NoteYear> filter(List<NoteYear> years, NoteBranch? branch) =>
      years
          .where(
            (year) =>
                branch == null || isCommon(year) || ofYear(year) == branch,
          )
          .toList();
}
