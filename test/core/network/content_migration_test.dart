import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:port/core/config/app_config.dart';
import 'package:port/core/network/github_sources.dart';
import 'package:port/core/storage/github_cache_migration.dart';
import 'package:port/features/notes/models/subject.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('old raw and GitHub download links migrate to their preserved locations', () {
    expect(
      GitHubSources.migrateLegacyLinks(
        'https://raw.githubusercontent.com/Academia-IGIT/DATA_hub/main/Notes/CSE%20Sem%203.json',
      ),
      'https://raw.githubusercontent.com/IamPritamAcharya/Alcademy/main/content/Notes/CSE%20Sem%203.json',
    );
    expect(
      GitHubSources.migrateLegacyLinks(
        'https://raw.githubusercontent.com/IamPritamAcharya/DATA_hub/main/Notes/firstyear.json',
      ),
      'https://raw.githubusercontent.com/IamPritamAcharya/Alcademy/main/content/legacy/iam-pritam-acharya/Notes/firstyear.json',
    );
    expect(
      GitHubSources.migrateLegacyLinks(
        'https://github.com/IamPritamAcharya/DATA_hub/raw/main/Untitled%20design.png',
      ),
      'https://raw.githubusercontent.com/IamPritamAcharya/Alcademy/main/content/Untitled%20design.png',
    );
    const external = 'https://drive.google.com/file/d/document/view';
    expect(GitHubSources.migrateLegacyLinks(external), external);
  });

  test(
    'cached content migrates once without losing profile, selection or offline data',
    () async {
      const old =
          'https://raw.githubusercontent.com/Academia-IGIT/DATA_hub/main/Notes/CSE%20Sem%203.json';
      SharedPreferences.setMockInitialValues({
        'userName': 'Student',
        'selectedYearUrl': old,
        'cachedYearLinks': jsonEncode([
          {'name': 'CSE Sem 3', 'url': old},
        ]),
        'storyUrls': jsonEncode([
          {
            'type': 'image',
            'url':
                'https://github.com/IamPritamAcharya/DATA_hub/raw/main/Untitled%20design.png',
          },
        ]),
        'lastFetchDate': '2026-10-07T12:00:00.000',
        'expenses': '[]',
      });
      final prefs = await SharedPreferences.getInstance();
      await migrateGitHubContentCache(prefs);
      expect(
        prefs.getString('selectedYearUrl'),
        GitHubSources.migrateLegacyLinks(old),
      );
      expect(
        jsonDecode(prefs.getString('cachedYearLinks')!).single['name'],
        'CSE Sem 3',
      );
      expect(
        jsonDecode(prefs.getString('storyUrls')!).single['url'],
        contains('/Alcademy/main/content/'),
      );
      expect(prefs.getString('userName'), 'Student');
      expect(prefs.getString('expenses'), '[]');
      expect(prefs.getString('lastFetchDate'), isNull);
      await prefs.setString('lastFetchDate', 'new fetch');
      await migrateGitHubContentCache(prefs);
      expect(prefs.getString('lastFetchDate'), 'new fetch');
    },
  );

  test(
    'all imported files exist and current notes/settings match app parsers',
    () {
      final manifest =
          jsonDecode(File('content/migration_manifest.json').readAsStringSync())
              as Map<String, dynamic>;
      final entries = manifest['files'] as List;
      expect(entries.map((e) => e['repository']).toSet(), {
        'Academia-IGIT/DATA_hub',
        'IamPritamAcharya/DATA_hub',
      });
      for (final entry in entries) {
        expect(
          File(entry['destination'] as String).existsSync(),
          isTrue,
          reason: entry['destination'] as String,
        );
      }
      for (final file in Directory(
        'content/Notes',
      ).listSync().whereType<File>()) {
        final subjects = (jsonDecode(file.readAsStringSync()) as List)
            .map((item) => Subject.fromJson(item as Map<String, dynamic>))
            .toList();
        expect(subjects, isNotEmpty, reason: file.path);
      }
      final config = AppConfig.fromJson(
        jsonDecode(File('content/settings.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      expect(config.stories, isNotEmpty);
      expect(config.contributors, isNotEmpty);
      expect(
        File(
          Uri.decodeComponent(
            Uri.parse(GitHubSources.defaultSubjects).path.split('/main/').last,
          ),
        ).existsSync(),
        isTrue,
      );
    },
  );
}
