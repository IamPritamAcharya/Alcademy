import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:port/app/theme.dart';
import 'package:port/core/config/app_config.dart';
import 'package:port/features/about/presentation/about_page.dart';
import '../support/load_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  setUp(
    () => AppConfiguration.current.value = AppConfig(
      contributors: [
        {
          'name': 'Campus notes contributor',
          'url': 'https://example.com/contributor',
        },
      ],
    ),
  );
  tearDown(() => AppConfiguration.current.value = AppConfig());

  Future<void> showPage(
    WidgetTester tester, {
    bool enlarged = false,
    Future<bool> Function(Uri)? openLink,
  }) async {
    tester.view.physicalSize = Size(enlarged ? 320 : 430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(enlarged ? 1.6 : 1)),
          child: child!,
        ),
        home: RepaintBoundary(
          key: const ValueKey('about-preview'),
          child: AboutPage(openLink: openLink),
        ),
      ),
    );
    await tester.runAsync(() async {
      final context = tester.element(find.byType(AboutPage));
      for (final asset in [
        'assets/images/me.jpg',
        'assets/images/codex.jpeg',
        'assets/images/insta.png',
        'assets/images/link.png',
      ]) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets(
    'About matches its editorial design without the removed sections',
    (tester) async {
      await showPage(tester);
      expect(find.textContaining('Swayanshu'), findsNothing);
      expect(find.textContaining('WhatsApp'), findsNothing);
      await expectLater(
        find.byKey(const ValueKey('about-preview')),
        matchesGoldenFile('../goldens/about.png'),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'About fits enlarged text and preserves the social and contributor links',
    (tester) async {
      final opened = <Uri>[];
      await showPage(
        tester,
        enlarged: true,
        openLink: (uri) async {
          opened.add(uri);
          return true;
        },
      );
      await tester.scrollUntilVisible(
        find.text('LinkedIn').hitTestable(),
        120,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('LinkedIn'));
      await tester.pumpAndSettle();
      expect(
        opened.single.toString(),
        'https://www.linkedin.com/in/pritamacharya/',
      );
      expect(find.text('YouTube'), findsNothing);
      await tester.ensureVisible(find.text('Discord'));
      await tester.tap(find.text('Discord'));
      await tester.pumpAndSettle();
      expect(
        opened.last.toString(),
        'https://discord.com/users/696411743894896650',
      );
      await tester.scrollUntilVisible(
        find.text('Notes contributors').hitTestable(),
        160,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Notes contributors'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Campus notes contributor'));
      await tester.tap(find.text('Campus notes contributor'));
      await tester.pumpAndSettle();
      expect(opened.last.toString(), 'https://example.com/contributor');
      AppConfiguration.current.value = AppConfig(
        contributors: [
          {'name': 'Updated contributor', 'url': 'https://example.com/new'},
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text('Updated contributor'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
