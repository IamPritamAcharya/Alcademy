import 'dart:convert';
import 'package:http/http.dart' as http;

class UserAccess {
  final String userId;
  final String clubId;

  UserAccess({required this.userId, required this.clubId});

  factory UserAccess.fromJson(Map<String, dynamic> json) {
    return UserAccess(
      userId: json['user_id'],
      clubId: json['club_id'],
    );
  }
}

Future<List<UserAccess>> fetchAllowedUsers() async {
  final response = await http.get(Uri.parse(
      'https://raw.githubusercontent.com/Academia-IGIT/DATA_hub/main/allowed.json'));

  if (response.statusCode == 200) {
    List<dynamic> jsonData = jsonDecode(response.body);
    return jsonData.map((item) => UserAccess.fromJson(item)).toList();
  } else {
    throw Exception("Failed to load allowed users");
  }
}
