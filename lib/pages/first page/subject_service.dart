import 'dart:convert';
import 'package:http/http.dart' as http;
import 'subject_model.dart';

class SubjectService {
  String _url; // Private mutable field for the URL

  SubjectService(String initialUrl) : _url = initialUrl;

  // Setter to update the URL dynamically
  set url(String newUrl) {
    _url = newUrl;
  }

  Future<List<Subject>> fetchSubjects() async {
    final response = await http.get(Uri.parse(_url));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((subjectJson) => Subject.fromJson(subjectJson)).toList();
    } else {
      throw Exception('Failed to load subjects');
    }
  }

  // Method with cache busting
  Future<List<Subject>> fetchSubjectsWithCacheBust() async {
    final cacheBustedUrl = '$_url?timestamp=${DateTime.now().millisecondsSinceEpoch}';
    final response = await http.get(Uri.parse(cacheBustedUrl));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((subjectJson) => Subject.fromJson(subjectJson)).toList();
    } else {
      throw Exception('Failed to load subjects with cache busting');
    }
  }
}
