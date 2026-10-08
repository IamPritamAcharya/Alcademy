import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:port/app/theme.dart';
import 'package:port/features/college_resources/data/erp_data_flow.dart';
import 'package:port/features/college_resources/data/holiday_source.dart';
import 'package:port/features/college_resources/presentation/holiday_list_page.dart';
import '../support/load_fonts.dart';

String fixture() => jsonEncode({
  'd': jsonEncode([
    {
      'HolidayName': 'WINTER BREAK',
      'FromDate': '24/12/2026',
      'ToDate': '02/01/2027',
      'Description': 'College closed',
    },
    {
      'HolidayName': 'COLLEGE HOLIDAY',
      'FromDate': '09/10/2026',
      'ToDate': '09/10/2026',
      'Description': 'Friday',
    },
  ]),
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
  final today = DateTime(2026, 10, 7);
  test('parses ERP fields, sorts dates and preserves cross-year ranges', () {
    final holidays = HolidaySource.parse(fixture());
    expect(holidays.first.name, 'COLLEGE HOLIDAY');
    expect(holidays.first.from, DateTime(2026, 10, 9));
    expect(holidays.last.to, DateTime(2027, 1, 2));
    expect(holidays.last.description, 'College closed');
    expect(HolidaySource.parse('{"d":"[]"}'), isEmpty);
  });
  test('rejects malformed dates, incomplete rows and reversed ranges', () {
    for (final rows in [
      [
        {
          'HolidayName': 'Holiday',
          'FromDate': '31/02/2026',
          'ToDate': '01/03/2026',
        },
      ],
      [
        {
          'HolidayName': 'Holiday',
          'FromDate': '10/10/2026',
          'ToDate': '09/10/2026',
        },
      ],
      [
        {'HolidayName': 'Holiday'},
      ],
    ]) {
      expect(
        () => HolidaySource.parse(jsonEncode({'d': rows})),
        throwsFormatException,
      );
    }
    expect(() => HolidaySource.parse('{"error":true}'), throwsFormatException);
  });
  test('decodes WebView strings and pending requests', () {
    final payload = jsonEncode({'data': jsonDecode(fixture())});
    expect(
      HolidaySource.parse(HolidaySource.decode(jsonEncode(payload))!).length,
      2,
    );
    expect(HolidaySource.decode('{"pending":true}'), isNull);
    expect(() => HolidaySource.decode('{"error":true}'), throwsFormatException);
    expect(() => HolidaySource.decode('{}'), throwsFormatException);
  });
  testWidgets(
    'ERP list and PDF remain available at narrow width and large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: HolidayListPage(
            clock: () => today,
            sessionBuilder:
                ({required onLoaded, required onError, required onStatus}) =>
                    _Session(() => onLoaded(HolidaySource.parse(fixture()))),
            pdfBuilder: (_) => const Scaffold(body: Text('PDF viewer')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Next holiday'), findsOneWidget);
      expect(find.text('View PDF'), findsOneWidget);
      expect(find.text('Official holiday PDF'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('View PDF'));
      await tester.pumpAndSettle();
      expect(find.text('PDF viewer'), findsOneWidget);
    },
  );
  for (final reason in [
    ErpDataFailure.credentialsRequired,
    ErpDataFailure.connection,
  ]) {
    testWidgets('PDF fallback works after $reason', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: HolidayListPage(
            sessionBuilder:
                ({required onLoaded, required onError, required onStatus}) =>
                    _Session(
                      () => onError(
                        ErpDataException(reason, 'ERP is unavailable.'),
                      ),
                    ),
            pdfBuilder: (_) => const Scaffold(body: Text('PDF viewer')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('View PDF'), findsOneWidget);
      expect(find.text('Official holiday PDF'), findsNothing);
      expect(
        find.text(
          reason == ErpDataFailure.credentialsRequired
              ? 'Connect ERP in Profile'
              : 'Try ERP again',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('View PDF'));
      await tester.pumpAndSettle();
      expect(find.text('PDF viewer'), findsOneWidget);
    });
  }
  testWidgets('failed pull refresh preserves the loaded holidays', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: HolidayListPage(
          clock: () => today,
          sessionBuilder:
              ({required onLoaded, required onError, required onStatus}) =>
                  _Session(() {
                    if (++calls == 1) {
                      onLoaded(HolidaySource.parse(fixture()));
                    } else {
                      onError(
                        const ErpDataException(
                          ErpDataFailure.connection,
                          'Offline',
                        ),
                      );
                    }
                  }),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Next holiday'), findsOneWidget);
    expect(
      find.text('Couldn’t refresh holidays. Keeping the current list.'),
      findsOneWidget,
    );
  });
}
