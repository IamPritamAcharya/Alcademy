import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:port/core/network/github_content_client.dart';
import 'package:port/features/notes/models/subject.dart';

class SubjectRepository {
  String _url;
  final GitHubContentClient _content;

  SubjectRepository(String initialUrl, {http.Client? client})
    : _url = initialUrl,
      _content = GitHubContentClient(client: client);

  set url(String newUrl) {
    _url = newUrl;
  }

  Future<List<Subject>> fetchSubjects() async {
    return _parse(await _content.getText(_url));
  }

  Future<List<Subject>> fetchSubjectsWithCacheBust() async {
    return _parse(await _content.getText(_url, cacheBust: true));
  }

  List<Subject> _parse(String text) => (jsonDecode(text) as List)
      .map((subjectJson) => Subject.fromJson(subjectJson))
      .toList();
}
