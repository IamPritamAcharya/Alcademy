# Shared PDF reader

Feature pages use `PdfDocumentPage` and `PdfDocumentSource` (network URL,
local file, or bytes). Do not import a PDF engine from feature code.

- `pdf_document_page.dart`: shared app bar, loading/errors, retry, saving and sharing.
- `pdfrx_document_view.dart`: the only engine adapter, including search and page controls.
- `pdf_document_repository.dart`: fetching and validation; public URL cache is
  limited to 20 files, with cleanup after seven days without use. HTTP cache
  headers govern freshness. Retry bypasses the cached file. Local/private files
  and supplied bytes are never copied into this public cache.
- `pdf_document_source.dart`: engine-independent inputs and PDF-link detection.

To change engines, replace the implementation of `PdfDocumentView` and update
the dependency in pubspec.yaml. Keep the same bytes/sourceName/onRetry contract;
feature pages and document actions need no changes.

Network links must return PDF bytes. Google Drive sharing pages, videos and
other websites retain their external browser behavior. ERP receipt downloads
retain authenticated fetching and saving; their bytes can be displayed with
`PdfDocumentSource.data` when a preview is needed.

The reader keeps the interface dark and the document's original page colors.
Search requires embedded text; scanned documents need OCR before text search
can work. Web downloads depend on the source's CORS policy.

Run shell/repository tests with `flutter test test/features/pdf_document_test.dart`.
The native rendering smoke test also needs `PDFIUM_PATH` pointing to the host's
PDFium shared library (downloaded by the native asset hook under
`.dart_tool/hooks_runner/shared/pdfium_dart/build/`). Without that variable the
native smoke test is skipped; the shell/repository tests still run. Flutter's
test executable does not locate the app's bundled PDFium automatically.
