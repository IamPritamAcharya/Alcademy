import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:port/app/theme.dart';
import 'package:port/features/results/data/results_cache.dart';
import 'package:port/features/results/data/results_parser.dart';
import 'package:port/features/results/data/results_source.dart';
import 'package:port/features/results/models/student_results.dart';
import 'package:port/features/results/presentation/results_page.dart';
import 'package:port/features/college_resources/data/erp_data_flow.dart';
import 'package:port/features/college_resources/data/erp_credentials_repository.dart';
import 'package:port/features/college_resources/data/erp_session_manager.dart';
import '../support/load_fonts.dart';

Map<String, dynamic> subject(
  String name,
  String code,
  String grade,
  String exam,
) => {
  'exam_held_id': exam,
  'subject_name': name,
  'sub_code': code,
  'sub_credit': 3.0,
  'srd_Grade_sub': grade, 'ssrd_SGPA': '8.50', 'ssrd_CGPA': '8.25',
  'ssrd_sgpa_credit': 21, 'result': 'PASS',
  // Synthetic extra personal fields must never survive parsing into the cache.
  'student_name': 'Example Student', 'enrollment_no': 'test-only',
};
String response({String grade = 'A', bool partial = false}) => jsonEncode({
  'exams': [
    {
      'record': {
        'Semester_Name': 'B.TECH CSE SEM-3',
        'exam_name': 'CSE-REGULAR-3RD-2026',
        'student_exam_type': 'Regular',
        'idt_date': '2026-09-01T00:00:00',
        'is_result_declare': 1,
      },
      'report': partial
          ? null
          : {
              'd': jsonEncode([
                subject(
                  'ARTIFICIAL INTELLIGENCE AND EXPERT SYSTEMS',
                  'CS301',
                  grade,
                  'CSE-REGULAR-3RD-2026',
                ),
                subject(
                  'COMPUTER GRAPHICS',
                  'CS302',
                  'O',
                  'CSE-REGULAR-3RD-2026',
                ),
              ]),
            },
    },
    {
      'record': {
        'Semester_Name': 'B.TECH CSE SEM-2',
        'exam_name': 'CSE-REGULAR-2ND-2026',
        'student_exam_type': 'Regular',
        'is_result_declare': 0,
      },
    },
  ],
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
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final clock = DateTime(2026, 10, 7, 10);
  StudentResults schedule({String grade = 'A', bool partial = false}) =>
      ResultsParser().parse(
        response(grade: grade, partial: partial),
        fetchedAt: clock,
      );
  test(
    'maps published grades and ERP SGPA/CGPA while omitting personal identifiers',
    () {
      final data = schedule();
      final result = data.exams.first;
      expect(result.report!.sgpa, '8.50');
      expect(result.report!.cgpa, '8.25');
      expect(result.report!.credits, '21');
      expect(result.report!.subjects.first.grade, 'A');
      expect(result.report!.subjects.first.credit, '3.0');
      expect(result.report!.status, 'PASS');
      expect(data.exams.last.declared, isFalse);
      expect(data.complete, isTrue);
      final json = jsonEncode(data.toJson());
      expect(json, isNot(contains('student_name')));
      expect(json, isNot(contains('test-only')));
    },
  );
  test(
    'never caches stale exam context, incomplete reports, or drops separate attempts',
    () async {
      const cache = ResultsCache();
      await cache.write(schedule());
      await cache.write(schedule(partial: true));
      expect((await cache.read(clock))!.exams.first.report, isNotNull);
      final wrongData = jsonDecode(response()) as Map<String, dynamic>;
      final wrongReport = wrongData['exams'][0]['report'] as Map;
      final wrongRows = jsonDecode(wrongReport['d'] as String) as List;
      for (final row in wrongRows) {
        row['exam_held_id'] = 'WRONG-EXAM';
      }
      wrongReport['d'] = jsonEncode(wrongRows);
      final wrong = ResultsParser().parse(jsonEncode(wrongData));
      expect(wrong.exams.first.report, isNull);
      expect(wrong.complete, isFalse);
      final data = jsonDecode(response()) as Map<String, dynamic>;
      final exams = data['exams'] as List;
      exams.add(exams.first);
      expect(
        ResultsParser()
            .parse(jsonEncode(data))
            .exams
            .where((e) => e.semesterNumber == 3)
            .length,
        2,
      );
    },
  );
  test(
    'cache expires by calendar month, round trips all grades, and clears for changed accounts',
    () async {
      const cache = ResultsCache();
      await cache.write(schedule());
      expect(
        (await cache.read(DateTime(2026, 10, 31, 23, 59)))!.toJson(),
        schedule().toJson(),
      );
      expect(await cache.read(DateTime(2026, 11, 1)), isNull);
      await cache.write(
        ResultsParser().parse(
          response(),
          fetchedAt: DateTime(2026, 12, 31, 23, 59),
        ),
      );
      expect(await cache.read(DateTime(2027, 1, 1)), isNull);
      await cache.write(schedule());
      await ErpSessionManager.invalidate();
      expect(await cache.read(clock), isNull);
      await (await SharedPreferences.getInstance()).setString(
        ErpSessionManager.resultsCacheKey,
        'bad',
      );
      expect(await cache.read(clock), isNull);
    },
  );
  test(
    'empty results are valid; failed and malformed responses are rejected',
    () {
      expect(ResultsParser().parse('{"exams":[]}').exams, isEmpty);
      expect(() => ResultsParser().parse('{}'), throwsFormatException);
      expect(ResultsSource.decode('{"pending":true}'), isNull);
      expect(ResultsSource.decode(jsonEncode(response())), response());
      expect(
        () => ResultsSource.decode('{"error":true}'),
        throwsFormatException,
      );
    },
  );
  test(
    'uses existing ERP session, or signs in once and navigates to the results target',
    () async {
      var reads = 0, logins = 0;
      final visits = <Uri>[];
      StudentResults? data;
      ErpDataFlow<StudentResults> flow() => ErpDataFlow<StudentResults>(
        target: ResultsSource.uri,
        resource: 'results',
        parse: ResultsParser().parse,
        readCredentials: () async {
          reads++;
          return const ErpCredentials(
            username: 'example',
            password: 'test-only',
          );
        },
        navigate: (url) async {
          visits.add(url);
        },
        signIn: (_) async {
          logins++;
          return true;
        },
        readMarkup: () async => response(),
        onLoaded: (value) => data = value,
        onError: (error) => fail(error.message),
        onStatus: (_) {},
      );
      final active = flow();
      await active.start();
      await active.pageFinished(ResultsSource.uri.toString());
      expect(reads, 0);
      expect(logins, 0);
      expect(data!.exams.length, 2);
      final expired = flow();
      await expired.start();
      await expired.pageFinished('https://igit.icrp.in/academic/Index.aspx');
      await expired.pageFinished(
        'https://igit.icrp.in/academic/Student-cp/Students_profile.aspx',
      );
      await expired.pageFinished(ResultsSource.uri.toString());
      expect(reads, 1);
      expect(logins, 1);
      expect(visits.last, ResultsSource.uri);
    },
  );
  test(
    'browser reads reports sequentially and rejects foreign report URLs',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'alcademy-results-js-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final script = File('${directory.path}/check.js');
      await script.writeAsString(
        'const extraction = ${jsonEncode(ResultsSource.script)};\n'
        r'''
      const foreign = process.argv[2] === 'foreign';
      global.window = {};
      global.location = {origin: 'https://igit.icrp.in', pathname: '/academic/Student-cp/Student_Result.aspx', href: 'https://igit.icrp.in/academic/Student-cp/Student_Result.aspx'};
      let active = null;
      const calls = [];
      global.fetch = async (url, options) => {
        const parsed = new URL(url, location.href);
        if (parsed.origin !== location.origin) throw new Error('Foreign fetch attempted');
        if (options.credentials !== 'same-origin') throw new Error('Session not reused');
        const body = options.body ? JSON.parse(options.body) : {};
        let data;
        if (parsed.pathname.endsWith('Student_Result.aspx/ListStudentResult')) {
          if (body.filter_mode !== 0) throw new Error('Incorrect exam filter');
          data = {d: JSON.stringify([1, 2].map(id => ({Semester_Name: 'SEM-' + id, exam_name: 'EXAM-' + id, is_result_declare: 1, swd_sem_id: id})))};
        } else if (parsed.pathname.endsWith('/GetStudResult')) {
          active = body.swd_sem_id;
          calls.push('select-' + active);
          data = {d: foreign ? 'https://example.com/report' : '/academic/Student-cp/Form_Result_view_subject.aspx'};
        } else if (options.method === 'POST') {
          calls.push('grades-' + active);
          data = {d: JSON.stringify([{exam_held_id: 'EXAM-' + active}])};
        } else {
          calls.push('page-' + active);
        }
        await new Promise(resolve => setImmediate(resolve));
        return {ok: true, url: parsed.href, json: async () => data, text: async () => '<html></html>'};
      };
      (async () => {
        const initial = JSON.parse(eval(extraction));
        if (initial.pending !== true) throw new Error('Expected pending state');
        for (let i = 0; i < 100 && window.__alcademyResults.pending; i++) await new Promise(resolve => setImmediate(resolve));
        const result = JSON.parse(eval(extraction));
        process.stdout.write(JSON.stringify({result, calls}));
      })().catch(error => { process.stderr.write(error.message); process.exitCode = 1; });
    ''',
      );
      for (final foreign in [false, true]) {
        final process = await Process.run('node', [
          script.path,
          if (foreign) 'foreign',
        ]);
        expect(process.exitCode, 0, reason: '${process.stderr}');
        final output = jsonDecode(process.stdout as String) as Map;
        final exams = output['result']['exams'] as List;
        expect(exams.length, 2);
        if (foreign) {
          expect(exams.every((row) => row['report'] == null), isTrue);
          expect(output['calls'], ['select-1', 'select-2']);
        } else {
          expect(output['calls'], [
            'select-1',
            'page-1',
            'grades-1',
            'select-2',
            'page-2',
            'grades-2',
          ]);
          expect(
            jsonDecode(exams.last['report']['d'] as String)[0]['exam_held_id'],
            'EXAM-2',
          );
        }
      }
    },
  );
  Future<void> pumpPage(
    WidgetTester tester, {
    double width = 430,
    double scale = 1,
    ResultsSessionBuilder? builder,
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
          key: const ValueKey('results-preview'),
          child: ResultsPage(
            clock: () => clock,
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

  testWidgets('results display full subject grades and allow exam selection', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(find.text('8.50'), findsOneWidget);
    expect(find.text('8.25'), findsOneWidget);
    expect(
      find.text('ARTIFICIAL INTELLIGENCE AND EXPERT SYSTEMS'),
      findsOneWidget,
    );
    expect(find.text('A'), findsOneWidget);
    await tester.tap(find.text('Sem 2'));
    await tester.pumpAndSettle();
    expect(find.text('This result has not been declared yet.'), findsOneWidget);
    expect(find.text('A'), findsNothing);
  });
  testWidgets(
    'monthly cache avoids ERP; pull refresh updates grades and errors retain saved results',
    (tester) async {
      await const ResultsCache().write(schedule());
      var loads = 0;
      await pumpPage(
        tester,
        builder: ({required onLoaded, required onError, required onStatus}) =>
            _Session(() {
              loads++;
              if (loads == 1) {
                onLoaded(schedule(grade: 'O'));
              } else {
                onError(
                  const ErpDataException(ErpDataFailure.connection, 'Offline'),
                );
              }
            }),
      );
      expect(loads, 0);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 450));
      await tester.pumpAndSettle();
      expect(loads, 1);
      expect(
        (await const ResultsCache().read(
          clock,
        ))!.exams.first.report!.subjects.first.grade,
        'O',
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 450));
      await tester.pumpAndSettle();
      expect(loads, 2);
      expect(find.text('O'), findsNWidgets(2));
    },
  );
  testWidgets('results fit a narrow screen with larger text', (tester) async {
    await pumpPage(tester, width: 320, scale: 1.6);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('results design preview', (tester) async {
    await pumpPage(tester);
    await expectLater(
      find.byKey(const ValueKey('results-preview')),
      matchesGoldenFile('../goldens/results.png'),
    );
  });
}
