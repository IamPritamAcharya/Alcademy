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
      GitHubSources.defaultSubjects,
    );
    expect(
      GitHubSources.migrateLegacyLinks(
        'https://github.com/IamPritamAcharya/DATA_hub/raw/main/Untitled%20design.png',
      ),
      'https://raw.githubusercontent.com/IamPritamAcharya/Alcademy/main/content/images/stories/welcome.png',
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
    'cached images and archived note links migrate after the first import',
    () async {
      SharedPreferences.setMockInitialValues({
        'github_content_migrated_to_alcademy_v1': true,
        'selectedYearUrl':
            'https://raw.githubusercontent.com/IamPritamAcharya/Alcademy/main/content/legacy/iam-pritam-acharya/Notes/2nd_CSE_3rdsem.json',
        'storyUrls':
            '[{"type":"image","url":"https://raw.githubusercontent.com/IamPritamAcharya/Alcademy/main/content/img/Subham%20Nayak.jpg"}]',
      });
      final prefs = await SharedPreferences.getInstance();
      await migrateGitHubContentCache(prefs);
      expect(
        prefs.getString('selectedYearUrl'),
        endsWith('/Notes/CSE%20Sem%203.json'),
      );
      expect(
        jsonDecode(prefs.getString('storyUrls')!).single['url'],
        endsWith('/images/success-stories/subham-nayak.jpg'),
      );
    },
  );

  test('internal content images resolve and no image is orphaned', () {
    final references = <String>{};
    for (final file in Directory(
      'content',
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.json') && !file.path.endsWith('.md')) continue;
      for (final match in RegExp(
        r'https://raw\.githubusercontent\.com/IamPritamAcharya/Alcademy/main/content/[^\s)"<>]+',
      ).allMatches(file.readAsStringSync())) {
        final path = Uri.decodeComponent(
          Uri.parse(match.group(0)!).path.split('/main/').last,
        );
        expect(File(path).existsSync(), isTrue, reason: '${file.path}: $path');
        references.add(path);
      }
    }
    for (final file in Directory(
      'content/images',
    ).listSync(recursive: true).whereType<File>()) {
      expect(
        references,
        contains(file.path),
        reason: 'Unused image: ${file.path}',
      );
    }
  });

  test('current notes and settings match app parsers', () {
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
  });
}
