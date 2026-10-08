import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:port/app/theme.dart';
import 'package:port/features/attendance/data/attendance_cache.dart';
import 'package:port/features/attendance/data/attendance_parser.dart';
import 'package:port/features/attendance/data/attendance_source.dart';
import 'package:port/features/attendance/models/attendance.dart';
import 'package:port/features/attendance/presentation/attendance_page.dart';
import 'package:port/features/college_resources/data/erp_data_flow.dart';
import 'package:port/features/college_resources/data/erp_session_manager.dart';
import '../support/load_fonts.dart';

// Synthetic responses use the exact ERP field names, without account IDs.
String response({int present = 8}) => jsonEncode({
  'months': {
    'd': jsonEncode([
      {
        'month': 'October - 2026',
        'month_no': 10,
        'month_year': 2026,
        'total_arrange_lect': 20,
        'total_lecture': 12,
        'present_lecture': present,
        'absent_lecture': 12 - present,
        'remaning': 8,
        'persentage': '${present * 100 / 12}%',
        'total_leave': 1,
        'percentage_leave': '8.33%',
        'aggr_leave': '75.00%',
      },
    ]),
  },
  'subjects': {
    'd': jsonEncode([
      {
        'sub_fullname': 'ARTIFICIAL INTELLIGENCE AND  EXPERT SYSTEMS',
        'tot_lect': 20,
        'tot_attendance_lect': 12,
        'present_lect': present,
        'absent_lect': 12 - present,
        'remaining_lect': 8,
        'persentage_lect': '66.67%',
        'total_leave': '1',
        'percentage_leave': '8.33%',
        'aggr_leave': '75.00%',
      },
      {
        'sub_fullname': 'COMPUTER GRAPHICS',
        'tot_lect': 10,
        'tot_attendance_lect': 0,
        'present_lect': 0,
        'absent_lect': 0,
        'remaining_lect': 10,
        'persentage_lect': '0.00%',
        'total_leave': '0',
        'percentage_leave': '0%',
        'aggr_leave': '0%',
      },
    ]),
  },
});

class _Session extends StatefulWidget {
  final VoidCallback complete;
  const _Session(this.complete);
  @override
  State<_Session> createState() => _SessionState();
}

class _SessionState extends State<_Session> {
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
  final clock = DateTime(2026, 10, 7, 10);
  Attendance schedule({int present = 8}) =>
      AttendanceParser().parse(response(present: present), fetchedAt: clock);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'parses both ERP datasets and keeps pending entries out of recorded totals',
    () {
      final data = schedule();
      expect(data.months.single.name, 'October - 2026');
      expect(
        data.subjects.first.name,
        'ARTIFICIAL INTELLIGENCE AND EXPERT SYSTEMS',
      );
      expect(data.subjects.first.pending, 8);
      expect(data.subjects.first.filled, 12);
      expect(data.subjects.first.leave, 1);
      expect(data.subjects.first.aggregatePercentage, 75);
      expect(data.percentage, 75);
      expect(data.filled, 12);
      expect(data.subjects.last.filled, 0);
      // Cache serialization excludes account identifiers even if ERP supplies them.
      expect(jsonEncode(data.toJson()), isNot(contains('stud_id')));
    },
  );
  test(
    'recognises only ERP’s real no-record messages and rejects malformed responses',
    () {
      final empty = AttendanceParser().parse(
        jsonEncode({
          'months': {'d': jsonEncode('Attendance record not found.')},
          'subjects': {
            'd': jsonEncode('Subject Wise Attendance record not found.'),
          },
        }),
      );
      expect(empty.months, isEmpty);
      expect(empty.subjects, isEmpty);
      expect(empty.percentage, isNull);
      expect(() => AttendanceParser().parse('{}'), throwsFormatException);
      expect(
        () =>
            AttendanceParser().parse(response().replaceFirst('66.67%', 'NaN%')),
        throwsFormatException,
      );
    },
  );
  test(
    'cache expires exactly at the next 9am, including midnight and year boundaries',
    () async {
      const cache = AttendanceCache();
      final early = AttendanceParser().parse(
        response(),
        fetchedAt: DateTime(2026, 10, 7, 8, 30),
      );
      await cache.write(early);
      expect(await cache.read(DateTime(2026, 10, 7, 8, 59, 59)), isNotNull);
      expect(await cache.read(DateTime(2026, 10, 7, 9)), isNull);
      await cache.write(schedule());
      expect(await cache.read(DateTime(2026, 10, 8)), isNotNull);
      expect(await cache.read(DateTime(2026, 10, 8, 8, 59, 59)), isNotNull);
      expect(await cache.read(DateTime(2026, 10, 8, 9)), isNull);
      expect(
        AttendanceCache.expiresAt(DateTime(2026, 12, 31, 9)),
        DateTime(2027, 1, 1, 9),
      );
      expect(
        AttendanceCache.expiresAt(DateTime(2028, 2, 29, 23)),
        DateTime(2028, 3, 1, 9),
      );
    },
  );
  test(
    'cache round trips all fields, invalidation removes it and corruption is ignored',
    () async {
      const cache = AttendanceCache();
      await cache.write(schedule());
      expect((await cache.read(clock))!.toJson(), schedule().toJson());
      await ErpSessionManager.invalidate();
      expect(await cache.read(clock), isNull);
      await (await SharedPreferences.getInstance()).setString(
        ErpSessionManager.attendanceCacheKey,
        'bad',
      );
      expect(await cache.read(clock), isNull);
    },
  );
  test('handles pending JS state and both native string encodings', () {
    expect(AttendanceSource.decode('{"pending":true}'), isNull);
    expect(AttendanceSource.decode(response()), response());
    expect(AttendanceSource.decode(jsonEncode(response())), response());
    expect(
      () => AttendanceSource.decode('{"error":true}'),
      throwsFormatException,
    );
  });
  test(
    'attendance reuses the active session without credentials or login',
    () async {
      final visits = <Uri>[];
      Attendance? result;
      final flow = ErpDataFlow<Attendance>(
        target: AttendanceSource.uri,
        resource: 'attendance',
        parse: AttendanceParser().parse,
        readCredentials: () async => throw StateError('must not read'),
        navigate: (url) async {
          visits.add(url);
        },
        signIn: (_) async => throw StateError('must not login'),
        readMarkup: () async => response(),
        onLoaded: (data) => result = data,
        onError: (error) => fail(error.message),
        onStatus: (_) {},
      );
      await flow.start();
      await flow.pageFinished(AttendanceSource.uri.toString());
      expect(visits, [AttendanceSource.uri]);
      expect(result!.subjects.length, 2);
    },
  );
  Future<void> pumpPage(
    WidgetTester tester, {
    double width = 430,
    double scale = 1,
    AttendanceSessionBuilder? builder,
    DateTime Function()? pageClock,
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
          key: const ValueKey('attendance-preview'),
          child: AttendancePage(
            clock: pageClock ?? () => clock,
            sessionBuilder:
                builder ??
                ({required onLoaded, required onError, required onStatus}) =>
                    _Session(() => onLoaded(schedule())),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('subject and month tabs show ERP counts and leave details', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(find.text('66.67%'), findsOneWidget);
    expect(find.text('No entries recorded'), findsOneWidget);
    await tester.tap(find.text('Months'));
    await tester.pumpAndSettle();
    expect(find.text('October - 2026'), findsOneWidget);
    await tester.tap(find.text('Leave & totals'));
    await tester.pumpAndSettle();
    expect(find.text('Leave credited as present'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'cached page bypasses ERP; pull refresh replaces data and failures preserve it',
    (tester) async {
      await const AttendanceCache().write(schedule());
      var loads = 0;
      await pumpPage(
        tester,
        builder: ({required onLoaded, required onError, required onStatus}) =>
            _Session(() {
              loads++;
              if (loads == 1) {
                onLoaded(schedule(present: 9));
              } else {
                onError(
                  const ErpDataException(ErpDataFailure.connection, 'Offline'),
                );
              }
            }),
      );
      expect(loads, 0);
      expect(find.byTooltip('Refresh attendance'), findsNothing);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 450));
      await tester.pumpAndSettle();
      expect(loads, 1);
      expect((await const AttendanceCache().read(clock))!.attended, 9);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 450));
      await tester.pumpAndSettle();
      expect(loads, 2);
      expect((await const AttendanceCache().read(clock))!.attended, 9);
      expect(find.text('9 of 12 attended'), findsOneWidget);
    },
  );
  testWidgets('attendance fits narrow screens and larger text', (tester) async {
    await pumpPage(tester, width: 320, scale: 1.6);
    await tester.tap(find.text('Months'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('an open cached page reloads at the 9am boundary', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 7, 8, 59, 58);
    await const AttendanceCache().write(
      AttendanceParser().parse(
        response(),
        fetchedAt: DateTime(2026, 10, 7, 8, 30),
      ),
    );
    var loads = 0;
    await pumpPage(
      tester,
      pageClock: () => now,
      builder: ({required onLoaded, required onError, required onStatus}) =>
          _Session(() {
            loads++;
            onLoaded(AttendanceParser().parse(response(), fetchedAt: now));
          }),
    );
    expect(loads, 0);
    now = DateTime(2026, 10, 7, 9);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(loads, 1);
    expect((await const AttendanceCache().read(now))!.fetchedAt, now);
    expect(tester.takeException(), isNull);
  });

  testWidgets('attendance design preview', (tester) async {
    await pumpPage(tester);
    await expectLater(
      find.byKey(const ValueKey('attendance-preview')),
      matchesGoldenFile('../goldens/attendance.png'),
    );
  });
}
