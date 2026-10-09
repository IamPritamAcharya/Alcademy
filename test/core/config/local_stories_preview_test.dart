import 'package:flutter_test/flutter_test.dart';
import 'package:port/core/config/local_stories_preview.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Local preview loads three custom stories before real fetched news',
    () async {
      SharedPreferences.setMockInitialValues({
        'storyUrls': 'saved production data',
      });
      final preview = await LocalStoriesPreview.load();
      expect(preview.customStories.length, 3);
      expect(preview.customStories.first['type'], 'image');
      expect(preview.customStories.first['url'], endsWith('/welcome.png'));
      expect(preview.customStories[1]['title'], 'A little less last-minute');
      expect(preview.customStories[2]['title'], 'Built together');
      expect(preview.dailyStories.length, 16);
      expect(
        preview.dailyStories.every((story) => story['kind'] == 'news'),
        isTrue,
      );
      expect(preview.stories.length, 19);
      expect(
        preview.dailyStories.every(
          (story) =>
              (story['imageUrl'] ?? '').isNotEmpty &&
              (story['title'] ?? '').trim().isNotEmpty &&
              (story['description'] ?? '').trim().isNotEmpty,
        ),
        isTrue,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('storyUrls'), 'saved production data');
    },
  );
}
