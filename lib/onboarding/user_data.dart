import 'package:shared_preferences/shared_preferences.dart';

class UserData {
  static const String _userNameKey = 'userName';
  static const String _userBranchKey = 'userBranch';

  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  static Future<void> saveUserBranch(String branch) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userBranchKey, branch);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<String?> getUserBranch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userBranchKey);
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userNameKey);
    await prefs.remove(_userBranchKey);
  }
}
