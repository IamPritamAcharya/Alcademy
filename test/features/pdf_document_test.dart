import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:port/app/theme.dart';
import 'package:port/shared/pdf/pdf_document_page.dart';
import 'package:port/shared/pdf/pdf_document_repository.dart';

class _Repository extends PdfDocumentRepository {
  final Future<Uint8List> Function(bool refresh) fetch;
  _Repository(this.fetch);
  @override
  Future<Uint8List> load(PdfDocumentSource source, {bool refresh = false}) =>
      fetch(refresh);
}

void main() {
  final bytes = Uint8List.fromList(utf8.encode('%PDF-1.4\nTest document'));

  testWidgets(
    'PDF engine opens a real document and exposes search and page controls',
    (tester) async {
      final pdf = _pdfFixture();
      await tester.runAsync(() async {
        Pdfrx.cacheDirectoryPath = Directory.systemTemp.path;
        Pdfrx.pdfiumModulePath = Platform.environment['PDFIUM_PATH'];
        await pdfrxFlutterInitialize();
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: PdfDocumentPage(
            source: PdfDocumentSource.data(pdf),
            title: 'Test PDF',
          ),
        ),
      );
      // Native rendering completes outside the fake test clock.
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        final cover = find.byKey(const ValueKey('pdf-loading-cover'));
        if (cover.evaluate().isNotEmpty &&
            tester.widget<AnimatedOpacity>(cover).opacity == 0) {
          break;
        }
      }
      expect(tester.takeException(), isNull);
      expect(find.text('1 / 1'), findsOneWidget);
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const ValueKey('pdf-loading-cover')),
            )
            .opacity,
        0,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Search PDF'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Search this PDF'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Hello');
      for (var i = 0; i < 30 && find.text('1/1').evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
      }
      expect(find.text('1/1'), findsOneWidget);
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Close search'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Search PDF'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
    skip: Platform.environment['PDFIUM_PATH'] == null,
  );

  test(
    'PDF links with query strings are recognized without accepting web pages',
    () {
      expect(
        PdfDocumentSource.isPdfLink(
          'https://college.test/NOTICE.PDF?download=1#page=2',
        ),
        true,
      );
      expect(
        PdfDocumentSource.isPdfLink('https://drive.google.com/file/d/id/view'),
        false,
      );
      expect(
        PdfDocumentSource.fileName('Exam / timetable'),
        'Exam _ timetable.pdf',
      );
      expect(PdfDocumentSource.fileName(''), 'Document.pdf');
    },
  );

  test('Byte inputs reject login HTML and accept PDF headers', () async {
    final repository = PdfDocumentRepository();
    expect(await repository.load(PdfDocumentSource.data(bytes)), bytes);
    await expectLater(
      repository.load(
        PdfDocumentSource.data(
          Uint8List.fromList(utf8.encode('<html>Login</html>')),
        ),
      ),
      throwsFormatException,
    );
  });

  test('Private file inputs load locally without the network cache', () async {
    final directory = await Directory.systemTemp.createTemp(
      'alcademy-pdf-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/private.pdf');
    await file.writeAsBytes(bytes);
    expect(
      await PdfDocumentRepository().load(PdfDocumentSource.file(file.path)),
      bytes,
    );
  });

  Future<void> mount(WidgetTester tester, PdfDocumentRepository repository) =>
      tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: PdfDocumentPage(
            title: 'College notice',
            source: const PdfDocumentSource.network(
              'https://college.test/notice.pdf',
            ),
            repository: repository,
            viewBuilder: (data, name, retry) =>
                Text('Rendered ${data.length} bytes'),
          ),
        ),
      );

  testWidgets(
    'Reader disables exports while loading and enables them after loading',
    (tester) async {
      final pending = Completer<Uint8List>();
      await mount(tester, _Repository((_) => pending.future));
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton && widget.tooltip == 'Download PDF',
              ),
            )
            .onPressed,
        isNull,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete(bytes);
      await tester.pumpAndSettle();
      expect(find.text('Rendered ${bytes.length} bytes'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton && widget.tooltip == 'Download PDF',
              ),
            )
            .onPressed,
        isNotNull,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton && widget.tooltip == 'Share PDF',
              ),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('Retry bypasses cache and replaces errors with the reader', (
    tester,
  ) async {
    var calls = 0;
    await mount(
      tester,
      _Repository((refresh) async {
        calls++;
        if (calls == 1) throw const FormatException('Not a PDF.');
        expect(refresh, true);
        return bytes;
      }),
    );
    await tester.pumpAndSettle();
    expect(find.text('Not a PDF.'), findsOneWidget);
    expect(find.text('Open in browser'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Rendered ${bytes.length} bytes'), findsOneWidget);
    expect(calls, 2);
  });
}

Uint8List _pdfFixture() {
  const stream = 'BT /F1 18 Tf 30 100 Td (Hello Alcademy) Tj ET';
  final objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 300 200] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    '<< /Length ${stream.length} >>\nstream\n$stream\nendstream',
  ];
  final output = StringBuffer('%PDF-1.4\n');
  final offsets = <int>[];
  for (var i = 0; i < objects.length; i++) {
    offsets.add(output.length);
    output.write('${i + 1} 0 obj\n${objects[i]}\nendobj\n');
  }
  final xref = output.length;
  output.write('xref\n0 6\n0000000000 65535 f \n');
  for (final offset in offsets) {
    output.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
  }
  output.write('trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n$xref\n%%EOF\n');
  return Uint8List.fromList(ascii.encode(output.toString()));
}
