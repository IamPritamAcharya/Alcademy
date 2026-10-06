import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:port/app/theme.dart';
import 'package:port/features/private_space/data/private_space_repository.dart';
import 'package:port/features/private_space/data/note_repository.dart';
import 'package:port/features/private_space/models/private_note.dart';
import 'package:port/features/private_space/presentation/private_page.dart';
import 'package:port/features/private_space/presentation/private_content_viewer.dart';
import 'package:port/features/private_space/presentation/note_editor.dart';
import '../../support/load_fonts.dart';

class _PrivateRepository extends PrivateSpaceRepository {
  @override
  Future<Directory> initialize() async => Directory('/tmp');
}

class _Notes extends NoteRepository {
  String? savedTitle;
  String? savedContent;
  @override
  Future<PrivateNote?> read(String filePath) async => const PrivateNote(
    title: 'Semester checklist',
    content: 'Revision notes, project ideas, and the things to remember.',
    createdAt: 1,
    modifiedAt: 1,
  );
  @override
  Future<String> save({
    required String title,
    required String content,
    String? filePath,
    Map<String, dynamic> metadata = const {},
  }) async {
    savedTitle = title;
    savedContent = content;
    return '/tmp/private-new-note.json';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'private_notes': ['/tmp/private-draft.json'],
    }),
  );

  Future<void> showPage(
    WidgetTester tester,
    Widget page, {
    bool enlarged = false,
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
          key: const ValueKey('private-preview'),
          child: page,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final category in {
    'photos': 'Add photo',
    'videos': 'Add video',
    'documents': 'Add document',
    'notes': 'New note',
  }.entries) {
    testWidgets(
      '${category.key} has an in-page Add control and left-aligned heading',
      (tester) async {
        await showPage(
          tester,
          PrivatePage(repository: _PrivateRepository(), notes: _Notes()),
          enlarged: true,
        );
        final card = find.byKey(ValueKey('private-${category.key}'));
        await tester.scrollUntilVisible(
          card.hitTestable(),
          200,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(find.byType(PrivateContentViewer), findsOneWidget);
        expect(
          find.widgetWithText(FilledButton, category.value),
          findsOneWidget,
        );
        final title = category.key[0].toUpperCase() + category.key.substring(1);
        expect(tester.getTopLeft(find.text(title)).dx, 20);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'adding a note from the collection keeps the route and refreshes its count',
    (tester) async {
      final notes = _Notes();
      await showPage(
        tester,
        PrivatePage(repository: _PrivateRepository(), notes: notes),
      );
      await tester.tap(find.byKey(const ValueKey('private-notes')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New note'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'New checklist');
      await tester.enterText(
        find.byType(TextField).at(1),
        'Remember the lab submission.',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(notes.savedTitle, 'New checklist');
      expect(notes.savedContent, 'Remember the lab submission.');
      expect(find.byType(PrivateContentViewer), findsOneWidget);
      expect(
        find.text('2 saved items · Hold an item for options'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('archive matches its redesigned screen', (tester) async {
    await showPage(
      tester,
      PrivatePage(repository: _PrivateRepository(), notes: _Notes()),
    );
    await expectLater(
      find.byKey(const ValueKey('private-preview')),
      matchesGoldenFile('../../goldens/private_archive.png'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('note editor fits large text and retains undo controls', (
    tester,
  ) async {
    await showPage(tester, const NoteEditor(), enlarged: true);
    await tester.tap(find.byTooltip('Edit note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Revision checklist');
    await tester.enterText(
      find.byType(TextField).last,
      'Read chapters one and two.',
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Undo'), findsOneWidget);
    expect(find.text('26 chars'), findsOneWidget);
    await tester.tap(find.byTooltip('Undo'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });
}
