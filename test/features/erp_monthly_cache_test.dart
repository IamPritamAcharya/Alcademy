import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:port/app/theme.dart';
import 'package:port/features/college_resources/data/erp_credentials_repository.dart';
import 'package:port/features/college_resources/data/erp_data_flow.dart';
import 'package:port/features/college_resources/data/erp_monthly_cache.dart';
import 'package:port/features/college_resources/data/erp_session_manager.dart';
import 'package:port/features/college_resources/models/college_holiday.dart';
import 'package:port/features/college_resources/presentation/erp_loading_panel.dart';
import 'package:port/features/college_resources/presentation/holiday_list_page.dart';
import 'package:port/features/fees/models/fee_record.dart';
import 'package:port/features/fees/presentation/fees_page.dart';
import '../support/load_fonts.dart';

FeeRecord fee({int paise = 10000}) => FeeRecord(
  amountPaise: paise,
  amountLabel: (paise / 100).toStringAsFixed(2),
  paymentType: 'ONLINE',
  accountHead: 'College fees',
  dateLabel: '01/10/2026',
  receiptNumber: 'TEST-1',
  orderId: 'ORDER-1',
  trackingId: 'TRACK-1',
  status: 'Success',
  paidAt: DateTime(2026, 10, 1),
  canDownload: true,
  items: const [FeeItem(head: 'Tuition', type: 'Term', amount: '100.00')],
);
CollegeHoliday holiday([String name = 'Holiday']) => CollegeHoliday(
  name: name,
  from: DateTime(2026, 10, 20),
  to: DateTime(2026, 10, 21),
  description: 'College closed',
);
final feesCache = ErpMonthlyCache<FeeRecord>(
  key: ErpSessionManager.feesCacheKey,
  fromJson: FeeRecord.fromJson,
  toJson: (row) => row.toJson(),
);
final holidaysCache = ErpMonthlyCache<CollegeHoliday>(
  key: ErpSessionManager.holidaysCacheKey,
  fromJson: CollegeHoliday.fromJson,
  toJson: (row) => row.toJson(),
);

class _Fetch extends StatefulWidget {
  final VoidCallback complete;
  const _Fetch(this.complete);
  @override
  State<_Fetch> createState() => _FetchState();
}

class _FetchState extends State<_Fetch> {
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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });
  test(
    'fees and holidays round trip through their calendar month only',
    () async {
      final fetched = DateTime(2026, 10, 1, 12);
      await feesCache.write([fee()], fetched);
      await holidaysCache.write([holiday()], fetched);
      final fees = await feesCache.read(DateTime(2026, 10, 31, 23, 59));
      expect(fees!.records.single.toJson(), fee().toJson());
      expect(
        (await holidaysCache.read(
          DateTime(2026, 10, 31),
        ))!.records.single.toJson(),
        holiday().toJson(),
      );
      expect(await feesCache.read(DateTime(2026, 11)), isNull);
      expect(await holidaysCache.read(DateTime(2026, 11)), isNull);
      expect(
        ErpMonthlyCache.expiresAt(DateTime(2026, 12, 31)),
        DateTime(2027, 1),
      );
      expect(
        ErpMonthlyCache.expiresAt(DateTime(2028, 2, 29)),
        DateTime(2028, 3),
      );
    },
  );
  test('future timestamps and corrupt data are discarded', () async {
    await feesCache.write([fee()], DateTime(2026, 10, 8));
    expect(await feesCache.read(DateTime(2026, 10, 7)), isNull);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ErpSessionManager.holidaysCacheKey, 'broken-json');
    expect(await holidaysCache.read(DateTime(2026, 10, 7)), isNull);
    expect(prefs.containsKey(ErpSessionManager.holidaysCacheKey), isFalse);
  });
  for (final change in ['same login', 'changed login', 'forgotten login']) {
    test('$change handles both ERP caches correctly', () async {
      const repository = ErpCredentialsRepository();
      const credentials = ErpCredentials(
        username: 'student',
        password: 'synthetic',
      );
      await repository.save(credentials);
      await feesCache.write([fee()], DateTime(2026, 10, 7));
      await holidaysCache.write([holiday()], DateTime(2026, 10, 7));
      if (change == 'forgotten login') {
        await repository.delete();
      } else {
        await repository.save(
          change == 'same login'
              ? credentials
              : const ErpCredentials(
                  username: 'another-student',
                  password: 'synthetic',
                ),
        );
      }
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.containsKey(ErpSessionManager.feesCacheKey),
        change == 'same login',
      );
      expect(
        prefs.containsKey(ErpSessionManager.holidaysCacheKey),
        change == 'same login',
      );
    });
  }
  for (final isFees in [true, false]) {
    final name = isFees ? 'Fees' : 'Holidays';
    testWidgets('$name opens cache without ERP and pull refresh replaces it', (
      tester,
    ) async {
      final now = DateTime(2026, 10, 7, 12);
      if (isFees) {
        await feesCache.write([fee()], DateTime(2026, 10, 1));
      } else {
        await holidaysCache.write([holiday()], DateTime(2026, 10, 1));
      }
      var calls = 0;
      final page = isFees
          ? FeesPage(
              clock: () => now,
              sessionBuilder:
                  ({required onLoaded, required onError, required onStatus}) =>
                      _Fetch(() {
                        calls++;
                        onLoaded([fee(paise: 20000)]);
                      }),
            )
          : HolidayListPage(
              clock: () => now,
              sessionBuilder:
                  ({required onLoaded, required onError, required onStatus}) =>
                      _Fetch(() {
                        calls++;
                        onLoaded([holiday('Updated holiday')]);
                      }),
            );
      await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: page));
      await tester.pumpAndSettle();
      expect(calls, 0);
      await tester.drag(find.byType(ListView), const Offset(0, 350));
      await tester.pumpAndSettle();
      expect(calls, 1);
      if (isFees) {
        final saved = (await feesCache.read(now))!;
        expect(saved.records.single.amountPaise, 20000);
        expect(saved.fetchedAt, now);
      } else {
        final saved = (await holidaysCache.read(now))!;
        expect(saved.records.single.name, 'Updated holiday');
        expect(saved.fetchedAt, now);
      }
    });
    testWidgets('$name failed pull refresh preserves its saved month', (
      tester,
    ) async {
      final now = DateTime(2026, 10, 7);
      final fetched = DateTime(2026, 10, 1);
      if (isFees) {
        await feesCache.write([fee()], fetched);
      } else {
        await holidaysCache.write([holiday()], fetched);
      }
      final page = isFees
          ? FeesPage(
              clock: () => now,
              sessionBuilder:
                  ({required onLoaded, required onError, required onStatus}) =>
                      _Fetch(
                        () => onError(
                          const ErpDataException(
                            ErpDataFailure.connection,
                            'Offline',
                          ),
                        ),
                      ),
            )
          : HolidayListPage(
              clock: () => now,
              sessionBuilder:
                  ({required onLoaded, required onError, required onStatus}) =>
                      _Fetch(
                        () => onError(
                          const ErpDataException(
                            ErpDataFailure.connection,
                            'Offline',
                          ),
                        ),
                      ),
            );
      await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: page));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 350));
      await tester.pumpAndSettle();
      expect(
        isFees
            ? (await feesCache.read(now))!.fetchedAt
            : (await holidaysCache.read(now))!.fetchedAt,
        fetched,
      );
      expect(find.byType(SnackBar), findsOneWidget);
    });
    testWidgets('$name refreshes at the next calendar month while open', (
      tester,
    ) async {
      var now = DateTime(2026, 10, 31, 23, 59, 58);
      if (isFees) {
        await feesCache.write([fee()], now);
      } else {
        await holidaysCache.write([holiday()], now);
      }
      var calls = 0;
      final page = isFees
          ? FeesPage(
              clock: () => now,
              sessionBuilder:
                  ({required onLoaded, required onError, required onStatus}) =>
                      _Fetch(() {
                        calls++;
                        onLoaded([fee()]);
                      }),
            )
          : HolidayListPage(
              clock: () => now,
              sessionBuilder:
                  ({required onLoaded, required onError, required onStatus}) =>
                      _Fetch(() {
                        calls++;
                        onLoaded([holiday()]);
                      }),
            );
      await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: page));
      await tester.pumpAndSettle();
      expect(calls, 0);
      now = DateTime(2026, 11, 1, 0, 0, 1);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(
        isFees
            ? (await feesCache.read(now))!.fetchedAt
            : (await holidaysCache.read(now))!.fetchedAt,
        now,
      );
    });
  }
  for (final isFees in [true, false]) {
    testWidgets(
      '${isFees ? 'Fees' : 'Holidays'} skeleton fits enlarged text and respects reduced motion',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: MediaQuery(
              data: const MediaQueryData(
                disableAnimations: true,
                textScaler: TextScaler.linear(1.6),
              ),
              child: Scaffold(
                body: isFees
                    ? const ErpLoadingPanel.fees(status: 'Checking ERP…')
                    : const ErpLoadingPanel.holidays(status: 'Checking ERP…'),
              ),
            ),
          ),
        );
        expect(
          tester
              .widgetList<Shimmer>(find.byType(Shimmer))
              .every((widget) => !widget.enabled),
          isTrue,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
