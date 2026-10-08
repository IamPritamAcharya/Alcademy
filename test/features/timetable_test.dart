import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:port/app/theme.dart';
import 'package:port/features/college_resources/data/erp_credentials_repository.dart';
import 'package:port/features/college_resources/data/erp_session_manager.dart';
import 'package:port/features/college_resources/presentation/erp_auto_login.dart';
import 'package:port/features/timetable/data/erp_timetable_flow.dart';
import 'package:port/features/timetable/data/erp_timetable_markup.dart';
import 'package:port/features/timetable/data/timetable_parser.dart';
import 'package:port/features/timetable/data/timetable_cache.dart';
import 'package:port/features/timetable/models/timetable.dart';
import 'package:port/features/timetable/presentation/timetable_page.dart';
import '../support/load_fonts.dart';

class _FakeSession extends StatefulWidget {
  final VoidCallback complete;
  const _FakeSession(this.complete);
  @override
  State<_FakeSession> createState() => _FakeSessionState();
}

class _FakeSessionState extends State<_FakeSession> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.complete();
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  final source = File('test/fixtures/erp_timetable.html').readAsStringSync();
  final clock = DateTime(2026, 10, 5, 9, 30);
  Timetable schedule() => TimetableParser().parse(source, fetchedAt: clock);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
    'maps merged labs to full duration and keeps other weekday columns aligned',
    () {
      final data = schedule();
      expect(data.division, 'B.TECH CSE SEM-3 DIVISION - B');
      expect(data.department, 'COMPUTER SCIENCE');
      expect(data.academicYear, '2026-2027');
      expect(data.effectiveFrom, '01 Jul 2026');
      final lab = data.forDay(1).first;
      expect(lab.startMinute, 540);
      expect(lab.endMinute, 690);
      expect(lab.classes.single.subject, 'PROJECT');
      expect(lab.classes.single.batch, 'B');
      expect(lab.classes.single.location, 'LABORATORY');
      expect(data.forDay(3).first.endMinute, 640);
      expect(data.forDay(4).single.classes.single.code, 'AL');
      expect(data.forDay(5).single.classes.map((item) => item.code), [
        'AL',
        'DS',
      ]);
      expect(data.forDay(6), isEmpty);
      expect(data.breaks.single.startMinute, 690);
      expect(data.breaks.single.endMinute, 840);
    },
  );

  test('metadata survives browser repair of ERP’s invalid table nesting', () {
    final repaired = source
        .replaceFirst('<tr><td><table id=', '<table id=')
        .replaceFirst('</table></td></tr></table>', '</table></table>');
    final data = TimetableParser().parse(repaired);
    expect(data.division, 'B.TECH CSE SEM-3 DIVISION - B');
    expect(data.academicYear, '2026-2027');
    expect(data.lessons.length, schedule().lessons.length);
  });

  test('cache round trips everything and expires by calendar month', () async {
    const cache = TimetableCache();
    await cache.write(schedule());
    final restored = (await cache.read(DateTime(2026, 10, 31, 23, 59)))!;
    expect(restored.faculty, schedule().faculty);
    expect(restored.subjects, schedule().subjects);
    expect(restored.division, schedule().division);
    expect(restored.lessons.length, schedule().lessons.length);
    expect(restored.forDay(1).first.classes.single.batch, 'B');
    expect(restored.breaks.single.endMinute, 840);
    expect(await cache.read(DateTime(2026, 11, 1)), isNull);
    // A fetch on the last day is valid for that day, not the next 30 days.
    await cache.write(
      TimetableParser().parse(source, fetchedAt: DateTime(2026, 12, 31, 23)),
    );
    expect(await cache.read(DateTime(2027, 1, 1)), isNull);
    await cache.write(
      TimetableParser().parse(source, fetchedAt: DateTime(2028, 2, 1)),
    );
    expect(await cache.read(DateTime(2028, 2, 29)), isNotNull);
    expect(await cache.read(DateTime(2028, 3, 1)), isNull);
  });

  test(
    'corrupt caches are discarded and account changes clear cached data',
    () async {
      const cache = TimetableCache();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ErpSessionManager.timetableCacheKey, '{bad');
      expect(await cache.read(clock), isNull);
      await cache.write(schedule());
      await ErpSessionManager.invalidate();
      expect(await cache.read(clock), isNull);
    },
  );

  test('HTML line breaks separate subject codes from room names', () {
    final data = TimetableParser().parse(
      source
          .replaceAll('AL R-101', 'AL<br/>BA-202')
          .replaceAll('B - PR LABORATORY', 'B - PR<br>LABORATORY'),
    );
    final item = data.forDay(2).first.classes.single;
    expect(item.code, 'AL');
    expect(item.title, 'ALGORITHMS');
    expect(item.location, 'BA-202');
    expect(item.label, 'AL\nBA-202');
    expect(data.forDay(1).first.classes.single.batch, 'B');
    expect(data.forDay(1).first.classes.single.location, 'LABORATORY');
    final unknown = TimetableParser().parse(
      source.replaceFirst('AL R-101', 'UNKNOWN<br/>BA-202'),
    );
    expect(unknown.forDay(2).first.classes.single.title, 'UNKNOWN\nBA-202');
  });

  test('retains both complete legends independently of scheduled classes', () {
    final data = schedule();
    expect(data.subjects, {
      'AL': 'ALGORITHMS',
      'DS': 'DATA STRUCTURES',
      'PR': 'PROJECT',
    });
    expect(data.faculty, {'TF': 'Example Faculty'});
    final standaloneFaculty = source.replaceFirst(
      '<tr><td>TF</td><td>►</td><td>Example Faculty</td></tr>',
      '<tr><td>P.M</td><td>►</td><td>Dr. Example Teacher</td></tr>',
    );
    expect(TimetableParser().parse(standaloneFaculty).faculty, {
      'P.M': 'Dr. Example Teacher',
    });
    expect(() => data.faculty['X'] = 'Y', throwsUnsupportedError);
  });

  test(
    'decodes both Android and WKWebView results without accepting missing data',
    () {
      final encoded = jsonEncode({'html': source});
      expect(ErpTimetableMarkup.decode(encoded), source);
      expect(ErpTimetableMarkup.decode(jsonEncode(encoded)), source);
      expect(() => ErpTimetableMarkup.decode('{}'), throwsFormatException);
      expect(() => ErpTimetableMarkup.decode(false), throwsFormatException);
    },
  );

  test(
    'does not lose duplicate-ID alternatives or invent faculty associations',
    () {
      final data = schedule();
      final options = data.forDay(5).single.classes;
      expect(options.length, 2);
      expect(options.map((item) => item.title), [
        'ALGORITHMS',
        'DATA STRUCTURES',
      ]);
      expect(options.map((item) => item.location), ['R-101', 'R-101']);
      expect(data.forDay(2).last.classes.length, 2);
    },
  );

  test(
    'keeps unknown ERP labels and rejects login pages and malformed merged cells',
    () {
      final unknown = TimetableParser().parse(
        source.replaceFirst('AL R-101', 'UNKNOWN R-999'),
      );
      expect(unknown.forDay(2).first.classes.single.title, 'UNKNOWN R-999');
      expect(
        () => TimetableParser().parse(
          '<form id="frm"><input id="txt_uname"></form>',
        ),
        throwsFormatException,
      );
      expect(
        () => TimetableParser().parse(
          source.replaceFirst('rowspan="3"', 'rowspan="99"'),
        ),
        throwsFormatException,
      );
      expect(
        () => TimetableParser().parse(
          source.replaceFirst('09:00 AM', '99:00 AM'),
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'active session loads timetable without reading credentials or posting login',
    () async {
      var reads = 0, signIns = 0;
      final urls = <Uri>[];
      Timetable? loaded;
      final flow = ErpTimetableFlow(
        readCredentials: () async {
          reads++;
          return null;
        },
        navigate: (uri) async {
          urls.add(uri);
        },
        signIn: (_) async {
          signIns++;
          return true;
        },
        readTimetable: () async => source,
        onLoaded: (data) => loaded = data,
        onError: (error) => fail(error.message),
        onStatus: (_) {},
      );
      await flow.start();
      await flow.pageFinished(ErpTimetableFlow.timetableUri.toString());
      expect(urls, [ErpTimetableFlow.timetableUri]);
      expect(loaded, isNotNull);
      expect(reads, 0);
      expect(signIns, 0);
    },
  );

  test(
    'expired session signs in once, returns from profile, then reads student timetable',
    () async {
      var signIns = 0;
      final urls = <Uri>[];
      Timetable? loaded;
      final flow = ErpTimetableFlow(
        readCredentials: () async =>
            const ErpCredentials(username: 'example', password: 'test-only'),
        navigate: (uri) async {
          urls.add(uri);
        },
        signIn: (_) async {
          signIns++;
          return true;
        },
        readTimetable: () async => source,
        onLoaded: (data) => loaded = data,
        onError: (error) => fail(error.message),
        onStatus: (_) {},
      );
      await flow.start();
      await flow.pageFinished(ErpAutoLogin.loginUri.toString());
      await flow.pageFinished(
        'https://igit.icrp.in/academic/Student-cp/Students_profile.aspx',
      );
      await flow.pageFinished(ErpTimetableFlow.timetableUri.toString());
      expect(signIns, 1);
      expect(urls, [
        ErpTimetableFlow.timetableUri,
        ErpTimetableFlow.timetableUri,
      ]);
      expect(loaded, isNotNull);
    },
  );

  test('wrong credentials stop after one attempt and never loop', () async {
    var signIns = 0;
    TimetableLoadException? failure;
    final flow = ErpTimetableFlow(
      readCredentials: () async =>
          const ErpCredentials(username: 'example', password: 'test-only'),
      navigate: (_) async {},
      signIn: (_) async {
        signIns++;
        return true;
      },
      readTimetable: () async => source,
      onLoaded: (_) => fail('must not load'),
      onError: (error) => failure = error,
      onStatus: (_) {},
    );
    await flow.pageFinished(ErpAutoLogin.loginUri.toString());
    await flow.pageFinished(ErpAutoLogin.loginUri.toString());
    await flow.pageFinished(ErpAutoLogin.loginUri.toString());
    expect(signIns, 1);
    expect(failure!.reason, TimetableFailure.authentication);
  });

  test(
    'missing credentials prompt setup and foreign redirects never receive credentials',
    () async {
      for (final url in [
        ErpAutoLogin.loginUri.toString(),
        'https://evil.example/academic/Index.aspx',
      ]) {
        var reads = 0;
        TimetableLoadException? failure;
        final flow = ErpTimetableFlow(
          readCredentials: () async {
            reads++;
            return null;
          },
          navigate: (_) async {},
          signIn: (_) async => throw StateError('unexpected login'),
          readTimetable: () async => source,
          onLoaded: (_) => fail('must not load'),
          onError: (error) => failure = error,
          onStatus: (_) {},
        );
        await flow.pageFinished(url);
        expect(reads, url == ErpAutoLogin.loginUri.toString() ? 1 : 0);
        expect(
          failure!.reason,
          url == ErpAutoLogin.loginUri.toString()
              ? TimetableFailure.credentialsRequired
              : TimetableFailure.connection,
        );
      }
    },
  );

  test(
    'disposing while reading credentials prevents subsequent submission',
    () async {
      final pending = Completer<ErpCredentials?>();
      var signIns = 0;
      final flow = ErpTimetableFlow(
        readCredentials: () => pending.future,
        navigate: (_) async {},
        signIn: (_) async {
          signIns++;
          return true;
        },
        readTimetable: () async => source,
        onLoaded: (_) => fail('disposed'),
        onError: (_) => fail('disposed'),
        onStatus: (_) {},
      );
      final event = flow.pageFinished(ErpAutoLogin.loginUri.toString());
      flow.cancel();
      pending.complete(
        const ErpCredentials(username: 'example', password: 'test-only'),
      );
      await event;
      expect(signIns, 0);
    },
  );

  test(
    'changing or forgetting credentials invalidates the shared cookie session, unchanged credentials retain it',
    () async {
      const repo = ErpCredentialsRepository();
      var clears = 0;
      Future<bool> clear() async {
        clears++;
        return true;
      }

      await ErpSessionManager.prepare(clearCookies: clear);
      expect(clears, 0);
      await repo.save(
        const ErpCredentials(username: 'example', password: 'test-only'),
      );
      await ErpSessionManager.prepare(clearCookies: clear);
      expect(clears, 1);
      await repo.save(
        const ErpCredentials(username: 'example', password: 'test-only'),
      );
      await ErpSessionManager.prepare(clearCookies: clear);
      expect(clears, 1);
      await repo.save(
        const ErpCredentials(username: 'other-example', password: 'test-only'),
      );
      await ErpSessionManager.prepare(clearCookies: clear);
      expect(clears, 2);
      await repo.delete();
      await ErpSessionManager.prepare(clearCookies: clear);
      expect(clears, 3);
    },
  );

  Future<void> pumpPage(
    WidgetTester tester, {
    double width = 430,
    double scale = 1,
    TimetableSessionBuilder? builder,
  }) async {
    tester.view.physicalSize = Size(width, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (_, child) => MediaQuery(
          data: MediaQueryData(
            size: Size(width, 932),
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: RepaintBoundary(
          key: const ValueKey('timetable-preview'),
          child: TimetablePage(
            clock: () => clock,
            sessionBuilder:
                builder ??
                ({required onLoaded, required onError, required onStatus}) =>
                    _FakeSession(() => onLoaded(schedule())),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'day selection shows full labs, alternatives and empty weekends',
    (tester) async {
      await pumpPage(tester);
      expect(find.text('Monday.'), findsOneWidget);
      expect(find.text('PROJECT'), findsOneWidget);
      expect(find.text('2h 30m'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Back to today'), findsNothing);
      await tester.tap(find.text('Tue'));
      await tester.pumpAndSettle();
      expect(find.text('Tuesday.'), findsOneWidget);
      expect(find.text('Today'), findsNothing);
      expect(find.text('TUESDAY’S LINEUP'), findsOneWidget);
      await tester.tap(find.text('Back to today'));
      await tester.pumpAndSettle();
      expect(find.text('Monday.'), findsOneWidget);
      await tester.tap(find.text('Tue'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Some periods list multiple subjects. All ERP entries are shown.',
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Sun'));
      await tester.tap(find.text('Sun'));
      await tester.pumpAndSettle();
      expect(find.text('Sunday.'), findsOneWidget);
      expect(find.text('A little breathing room.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('timetable fits narrow screens and enlarged text', (
    tester,
  ) async {
    await pumpPage(tester, width: 320, scale: 1.6);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -550));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('both legends expand with full names on a narrow screen', (
    tester,
  ) async {
    await pumpPage(tester, width: 320, scale: 1.6);
    await tester.scrollUntilVisible(
      find.text('Faculty full names'),
      250,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(find.text('Faculty full names'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Faculty full names'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Example Faculty'));
    expect(find.text('TF'), findsOneWidget);
    expect(find.text('Example Faculty'), findsOneWidget);
    await tester.ensureVisible(find.text('Subject full names'));
    await tester.tap(find.text('Subject full names'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('DATA STRUCTURES'));
    expect(find.text('DS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'missing login offers credentials and failed loads can be retried',
    (tester) async {
      var completions = 0;
      await pumpPage(
        tester,
        builder: ({required onLoaded, required onError, required onStatus}) =>
            _FakeSession(() {
              completions++;
              if (completions == 1) {
                onError(
                  const TimetableLoadException(
                    TimetableFailure.credentialsRequired,
                    'Save your ERP credentials in Profile.',
                  ),
                );
              } else {
                onLoaded(schedule());
              }
            }),
      );
      expect(find.text('Connect your ERP.'), findsOneWidget);
      expect(find.text('Edit ERP credentials'), findsOneWidget);
      // The app bar no longer offers a reload control.
      expect(find.byTooltip('Refresh timetable'), findsNothing);
      // Remount so the new fake connection receives a fresh session.
      await tester.pumpWidget(const SizedBox());
      await pumpPage(
        tester,
        builder: ({required onLoaded, required onError, required onStatus}) =>
            _FakeSession(() {
              completions++;
              if (completions == 2) {
                onError(
                  const TimetableLoadException(
                    TimetableFailure.connection,
                    'Offline',
                  ),
                );
              } else {
                onLoaded(schedule());
              }
            }),
      );
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Monday.'), findsOneWidget);
      expect(completions, 3);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cached page skips ERP, pull refresh replaces it, errors retain it',
    (tester) async {
      await const TimetableCache().write(schedule());
      var loads = 0;
      await pumpPage(
        tester,
        builder: ({required onLoaded, required onError, required onStatus}) =>
            _FakeSession(() {
              loads++;
              if (loads == 1) {
                onLoaded(
                  TimetableParser().parse(
                    source.replaceAll('PROJECT', 'UPDATED PROJECT'),
                    fetchedAt: clock,
                  ),
                );
              } else {
                onError(
                  const TimetableLoadException(
                    TimetableFailure.connection,
                    'Offline',
                  ),
                );
              }
            }),
      );
      expect(loads, 0);
      expect(find.text('PROJECT'), findsOneWidget);
      expect(find.byTooltip('Refresh timetable'), findsNothing);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 450));
      await tester.pumpAndSettle();
      expect(loads, 1);
      expect(find.text('UPDATED PROJECT'), findsOneWidget);
      expect(
        (await const TimetableCache().read(clock))!.subjects['PR'],
        'UPDATED PROJECT',
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 450));
      await tester.pumpAndSettle();
      expect(loads, 2);
      expect(find.text('UPDATED PROJECT'), findsOneWidget);
      expect(
        (await const TimetableCache().read(clock))!.subjects['PR'],
        'UPDATED PROJECT',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('native timetable design preview', (tester) async {
    await pumpPage(tester);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('timetable-preview')),
      matchesGoldenFile('../goldens/timetable.png'),
    );
  });
}
