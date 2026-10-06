import 'dart:math';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import '../../../core/network/app_http_client.dart';
import '../models/notice.dart';

class NoticeRepository {
  final http.Client _client;
  final DateTime Function() _now;
  NoticeRepository({http.Client? client, DateTime Function()? now})
      : _client = client ?? appHttpClient,
        _now = now ?? DateTime.now;

  Future<List<Notice>> fetch() async {
    final url = Uri.https('igitsarang.ac.in', '/notice/${_now().year}',
        {'random': '${Random().nextInt(100000)}'});
    final response = await _client.get(url).timeout(requestTimeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch notices.');
    }
    final document = html_parser.parse(response.body);
    final notices = <Notice>[];
    for (final row in document.querySelectorAll('tr[id^="noticerow_"]')) {
      // A partial row should not prevent the other notices from loading.
      if (row.children.length < 3) continue;
      final titleCell = row.children[0];
      var link = titleCell.querySelector('a')?.attributes['href'] ?? '';
      if (link.isEmpty || link == '#') {
        link = row.children[2].querySelector('a')?.attributes['href'] ?? '#';
      }
      notices.add(Notice(
          title: titleCell.text.trim(),
          date: row.children[1].text.trim(),
          downloadLink: link));
    }
    return notices;
  }
}
