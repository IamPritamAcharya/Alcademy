import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:port/app/theme.dart';
import 'package:port/features/stories/presentation/story_text_content.dart';
import 'package:port/shared/theme/app_style.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('ProductSans')
          ..addFont(rootBundle.load('assets/fonts/Product Sans Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Product Sans Bold.ttf')))
        .load();
  });

  for (final entry in {
    '[Read the guide](https://example.com/guide)': 'Read the guide',
    'https://example.com/guide': 'https://example.com/guide',
    'www.example.com/guide': 'www.example.com/guide',
  }.entries) {
    testWidgets('Story link is clickable: ${entry.key}', (tester) async {
      String? opened;
      var parentTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: GestureDetector(
              onTapUp: (_) => parentTaps++,
              child: StoryTextContent(
                text: entry.key,
                seed: 1,
                onTapLink: (_, url, _) => opened = url,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry.value, findRichText: true));
      expect(opened, contains('example.com/guide'));
      expect(
        parentTaps,
        0,
        reason: 'Opening a link must not advance the story.',
      );
    });
  }

  testWidgets('Stories render emphasis and fit long content without scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: StoryTextContent(
              text:
                  '**Important** and *welcome*\n\n${List.filled(14, '- A detailed campus update for students').join('\n')}\n\nFinal paragraph',
              seed: 2,
              onTapLink: (_, _, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final spans = <TextSpan>[];
    for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
      void collect(InlineSpan span) {
        if (span is TextSpan) {
          spans.add(span);
          for (final child in span.children ?? <InlineSpan>[]) {
            collect(child);
          }
        }
      }

      collect(rich.text);
    }
    expect(
      spans.any(
        (span) =>
            span.text == 'Important' &&
            span.style?.fontWeight == FontWeight.bold,
      ),
      true,
    );
    expect(
      spans.any(
        (span) =>
            span.text == 'welcome' && span.style?.fontStyle == FontStyle.italic,
      ),
      true,
    );
    expect(find.byType(Scrollable), findsNothing);
    expect(find.text('Final paragraph', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Custom story stays centered with a tight gap and no repeated heading',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Future<void> show(String body) => tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: StoryTextContent(
              title: 'A little less last-minute',
              text: '**A little less last-minute.**\n\n$body',
              seed: 1,
              onTapLink: (_, _, _) {},
            ),
          ),
        ),
      );
      await show('A short campus update.');
      final heading = find.byKey(const Key('custom-story-title'));
      final position = tester.getRect(heading);
      expect(find.byIcon(Icons.format_quote_rounded), findsNothing);
      final bodyPosition = tester.getRect(
        find.text('A short campus update.', findRichText: true),
      );
      expect(bodyPosition.top - position.bottom, inInclusiveRange(0, 18));
      expect(
        find.text('A little less last-minute.', findRichText: true),
        findsNothing,
      );
      final group = find.byKey(const Key('custom-story-group'));
      expect(tester.getCenter(group).dy, closeTo(260, .1));
      await show(List.filled(20, 'A much longer campus update.').join(' '));
      expect(tester.getCenter(group).dy, closeTo(260, .1));
      expect(find.byType(Scrollable), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Text story pattern variants', (tester) async {
    tester.view.physicalSize = const Size(860, 2500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: RepaintBoundary(
            key: const ValueKey('patterns'),
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 430 / 500,
              children: List.generate(
                10,
                (index) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.alphaBlend(
                          AppStyle
                              .highlights[index % AppStyle.highlights.length]
                              .withValues(alpha: .22),
                          AppStyle.background,
                        ),
                        AppStyle.background,
                      ],
                    ),
                  ),
                  child: StoryTextContent(
                    text:
                        '## Around campus\n\nA little room for **new ideas**.\n\n[See what’s happening](https://example.com)',
                    seed: index,
                    onTapLink: (_, _, _) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('patterns')),
      matchesGoldenFile('../goldens/story_patterns.png'),
    );
  });
}
