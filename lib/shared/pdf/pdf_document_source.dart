import 'dart:typed_data';

/// App-owned document input. Feature pages never depend on a PDF package.
class PdfDocumentSource {
  final String? url;
  final String? filePath;
  final Uint8List? bytes;

  const PdfDocumentSource.network(String this.url)
    : filePath = null,
      bytes = null;
  const PdfDocumentSource.file(String this.filePath) : url = null, bytes = null;
  const PdfDocumentSource.data(Uint8List this.bytes)
    : url = null,
      filePath = null;

  static bool isPdfLink(String value) =>
      Uri.tryParse(value)?.path.toLowerCase().endsWith('.pdf') ?? false;

  static String fileName(String title) {
    final name = title.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '_').trim();
    final trimmed = name.isEmpty ? 'Document' : name;
    final bounded = trimmed.length > 100 ? trimmed.substring(0, 100) : trimmed;
    return bounded.toLowerCase().endsWith('.pdf') ? bounded : '$bounded.pdf';
  }
}
