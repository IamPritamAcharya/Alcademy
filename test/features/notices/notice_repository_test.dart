import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:port/features/notices/data/notice_repository.dart';

void main() {
  test('Current-year notices support both link columns and ignore partial rows',
      () async {
    final repository = NoticeRepository(
        now: () => DateTime(2026),
        client: MockClient((request) async {
          expect(request.url.path, '/notice/2026');
          return http.Response('''<table>
        <tr id="noticerow_1"><td><a href="https://example.com/first.pdf">First notice</a></td><td>6 October</td><td></td></tr>
        <tr id="noticerow_2"><td><a href="#">Second notice</a></td><td>5 October</td><td><a href="https://example.com/second.pdf">Download</a></td></tr>
        <tr id="noticerow_3"><td>Incomplete</td></tr>
      </table>''', 200);
        }));
    final notices = await repository.fetch();
    expect(notices.map((notice) => notice.title),
        ['First notice', 'Second notice']);
    expect(notices[0].downloadLink, 'https://example.com/first.pdf');
    expect(notices[1].downloadLink, 'https://example.com/second.pdf');
  });
}
