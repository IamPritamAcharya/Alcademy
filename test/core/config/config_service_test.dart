import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:port/core/config/app_config.dart';
import 'package:port/core/config/config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
      'Cached settings publish immediately and a failed refresh preserves them',
      () async {
    SharedPreferences.setMockInitialValues({
      'name_1st_tab': 'Saved tab',
      'showFirstTab': false,
      'storyUrls': '[{"type":"text","text":"Saved story"}]',
    });
    await ConfigService.loadCachedConfig();
    expect(nameFirstTab, 'Saved tab');
    expect(showFirstTab, isFalse);
    final cached = AppConfiguration.current.value;
    await ConfigService.fetchAndUpdateConfig(
        client: MockClient((_) async => http.Response('broken', 200)));
    expect(identical(AppConfiguration.current.value, cached), isTrue);
    expect((await SharedPreferences.getInstance()).getString('lastFetchDate'),
        isNull);
  });

  test('Successful refresh publishes a complete immutable configuration',
      () async {
    SharedPreferences.setMockInitialValues({});
    var notifications = 0;
    void listener() => notifications++;
    AppConfiguration.current.addListener(listener);
    addTearDown(() => AppConfiguration.current.removeListener(listener));
    await ConfigService.fetchAndUpdateConfig(
        client: MockClient((_) async => http.Response(
            '{"name_1st_tab":"New tab","storyUrls":[],"contributors":[],"showFirstTab":true}',
            200)));
    expect(nameFirstTab, 'New tab');
    expect(notifications, 1);
    expect(() => storyUrls.add({'type': 'text'}), throwsUnsupportedError);
    expect((await SharedPreferences.getInstance()).getString('name_1st_tab'),
        'New tab');
  });
}
