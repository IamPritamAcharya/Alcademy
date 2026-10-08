import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:port/app/theme.dart';
import 'package:port/features/college_resources/data/erp_data_flow.dart';
import 'package:port/features/fees/data/fees_parser.dart';
import 'package:port/features/fees/data/fees_source.dart';
import 'package:port/features/fees/presentation/fees_page.dart';
import '../support/load_fonts.dart';

String fixture({String amount = '3,700.00', String status = 'Success'}) =>
    '''
<table id="ctl00_ContentPlaceHolder1_grd_inst_fee"><tr><th>Paid Amount</th><th>Pay Fee</th></tr>
<tr><td><span id="ctl00_ContentPlaceHolder1_grd_inst_fee_ctl02_lbl_fee_type">$amount</span></td>
<td><span id="ctl00_ContentPlaceHolder1_grd_inst_fee_ctl02_lbl_pay_type">ONLINE</span>
<span id="ctl00_ContentPlaceHolder1_grd_inst_fee_ctl02_lbl_account_head">College fees</span>
<span id="ctl00_ContentPlaceHolder1_grd_inst_fee_ctl02_lbl_pay_date">09/10/2026</span>
<span id="ctl00_ContentPlaceHolder1_grd_inst_fee_ctl02_lbl_receipt_no">TEST-001</span>
<span id="ctl00_ContentPlaceHolder1_grd_inst_fee_ctl02_lbl_bank_acc">ORDER-001</span>
<span id="ctl00_ContentPlaceHolder1_grd_inst_fee_ctl02_lbl_status">$status</span>
<a id="ctl00_ContentPlaceHolder1_grd_inst_fee_ctl02_lnk_print" href="javascript:__doPostBack('ctl00\$ContentPlaceHolder1\$grd_inst_fee\$ctl02\$lnk_print','')">Print</a>
</td></tr><tr><td colspan="2"><table id="ctl00_ContentPlaceHolder1_grd_inst_fee_ctl02_grd_child"><tr><th>Head Name</th><th>Fee Type</th><th>Amount</th></tr>
<tr><td>Tuition</td><td>Term fee</td><td>3,700.00</td></tr></table></td></tr></table>
''';

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
  final pdf = Uint8List.fromList(
    utf8.encode('%PDF-1.4\nsynthetic test receipt'),
  );
  test('parses amounts exactly, payment details and nested fee heads', () {
    final record = FeesParser.parse(fixture()).single;
    expect(record.amountPaise, 370000);
    expect(record.paidAt, DateTime(2026, 10, 9));
    expect(record.receiptNumber, 'TEST-001');
    expect(record.items.single.head, 'Tuition');
    expect(record.canDownload, isTrue);
    expect(FeesSource.fileName(record), 'Alcademy-receipt-TEST-001.pdf');
    expect(FeesParser.parse('<div data-fees-empty></div>'), isEmpty);
    expect(
      () => FeesParser.parse(fixture(amount: 'Invalid')),
      throwsFormatException,
    );
    expect(() => FeesParser.parse('<html>Login</html>'), throwsFormatException);
  });
  test('decodes WebView markup and rejects non-PDF receipts', () {
    expect(FeesSource.decodeMarkup(jsonEncode(fixture())), fixture());
    expect(FeesSource.decodeReceipt('{"pending":true}'), isNull);
    expect(
      FeesSource.parseReceipt(
        FeesSource.decodeReceipt(jsonEncode({'pdf': base64Encode(pdf)}))!,
      ),
      pdf,
    );
    expect(
      () => FeesSource.parseReceipt(
        base64Encode(utf8.encode('<html>Login</html>')),
      ),
      throwsFormatException,
    );
    expect(
      () => FeesSource.decodeReceipt('{"error":true}'),
      throwsFormatException,
    );
  });
  for (final paymentLink in [false, true]) {
    test(
      'receipt JS ${paymentLink ? "rejects payment actions" : "posts only the receipt action"}',
      () {
        final record = FeesParser.parse(fixture()).single;
        final event = paymentLink
            ? 'ctl00\$ContentPlaceHolder1\$btn_pay'
            : 'ctl00\$ContentPlaceHolder1\$grd_inst_fee\$ctl02\$lnk_print';
        final script =
            '''
        global.location = {origin: 'https://igit.icrp.in', pathname: '/academic/Student-cp/Form_students_pay_fees.aspx'};
        global.window = {};
        let request;
        const values = ${jsonEncode({'lbl_receipt_no': record.receiptNumber, 'lbl_fee_type': record.amountLabel, 'lbl_pay_date': record.dateLabel})};
        const row = {querySelector(selector) {
          if (selector.startsWith('a[')) return {getAttribute: () => ${jsonEncode("javascript:__doPostBack('$event','')")}};
          const name = Object.keys(values).find(key => selector.includes(key));
          return name ? {textContent: values[name]} : null;
        }};
        global.document = {
          querySelector: () => ({rows: [row]}),
          getElementById: () => ({querySelectorAll(selector) {
            if (selector !== 'input[type="hidden"][name]') throw new Error('Payment fields selected');
            return [{name: '__VIEWSTATE', value: 'synthetic-state'}];
          }})
        };
        global.fetch = async (url, options) => {
          request = Object.fromEntries(new URLSearchParams(options.body));
          return {ok: true, url: location.origin + location.pathname,
            arrayBuffer: async () => new TextEncoder().encode('%PDF-1.4 test').buffer};
        };
        eval(${jsonEncode(FeesSource.receiptScript(record))});
        setTimeout(() => console.log(JSON.stringify({request, result: window.__alcademyReceipt})), 20);
      ''';
        final result = Process.runSync('node', ['-e', script]);
        expect(result.exitCode, 0, reason: result.stderr.toString());
        final data = jsonDecode(result.stdout.toString()) as Map;
        if (paymentLink) {
          expect(data['request'], isNull);
          expect(data['result']['error'], isTrue);
        } else {
          expect(data['request']['__EVENTTARGET'], event);
          expect(data['request']['__EVENTARGUMENT'], '');
          expect(data['result']['pdf'], isNotEmpty);
        }
      },
    );
  }
  testWidgets('native fees UI fits large text and has no payment action', (
    tester,
  ) async {
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
        home: FeesPage(
          sessionBuilder:
              ({required onLoaded, required onError, required onStatus}) =>
                  _Session(() => onLoaded(FeesParser.parse(fixture()))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pay Fee'), findsNothing);
    expect(find.byTooltip('Download receipt TEST-001'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'download saves authenticated PDF and cancellation allows retry',
    (tester) async {
      var saves = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: FeesPage(
            sessionBuilder:
                ({required onLoaded, required onError, required onStatus}) =>
                    _Session(() => onLoaded(FeesParser.parse(fixture()))),
            receiptBuilder:
                ({
                  required record,
                  required onLoaded,
                  required onError,
                  required onStatus,
                }) => _Session(() => onLoaded(pdf)),
            saveReceipt: (name, bytes) async {
              expect(name, 'Alcademy-receipt-TEST-001.pdf');
              expect(bytes, pdf);
              return ++saves == 1 ? null : Uri.parse('file:///Downloads/$name');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Download receipt TEST-001'));
      await tester.pumpAndSettle();
      expect(saves, 1);
      expect(find.text('Receipt downloaded.'), findsNothing);
      await tester.tap(find.byTooltip('Download receipt TEST-001'));
      await tester.pumpAndSettle();
      expect(saves, 2);
      expect(find.text('Receipt downloaded.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('receipt error preserves records without invoking save', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: FeesPage(
          sessionBuilder:
              ({required onLoaded, required onError, required onStatus}) =>
                  _Session(() => onLoaded(FeesParser.parse(fixture()))),
          receiptBuilder:
              ({
                required record,
                required onLoaded,
                required onError,
                required onStatus,
              }) => _Session(
                () => onError(
                  const ErpDataException(
                    ErpDataFailure.connection,
                    'Receipt unavailable',
                  ),
                ),
              ),
          saveReceipt: (_, bytes) async {
            fail('Save should not run');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Download receipt TEST-001'));
    await tester.pumpAndSettle();
    expect(find.text('Receipt unavailable'), findsOneWidget);
    expect(find.text('Receipt TEST-001'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
