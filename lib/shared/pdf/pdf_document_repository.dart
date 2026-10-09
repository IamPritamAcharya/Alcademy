import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'pdf_document_source.dart';

/// Only public network documents are cached. Local/private PDFs stay local.
class PdfDocumentRepository {
  static final _cache = CacheManager(
    Config(
      'alcademy_public_pdfs_v1',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 20,
    ),
  );
  static const _maxBytes = 64 * 1024 * 1024;

  Future<Uint8List> load(
    PdfDocumentSource source, {
    bool refresh = false,
  }) async {
    final Uint8List bytes;
    if (source.bytes != null) {
      bytes = source.bytes!;
    } else if (source.filePath != null) {
      bytes = await _readFile(File(source.filePath!));
    } else {
      final uri = Uri.parse(source.url!);
      if (!['http', 'https'].contains(uri.scheme) || uri.host.isEmpty) {
        throw const FormatException('Invalid document link.');
      }
      if (kIsWeb) {
        final response = await http
            .get(uri)
            .timeout(const Duration(seconds: 30));
        if (response.statusCode != 200) {
          throw const FormatException('Download failed.');
        }
        bytes = response.bodyBytes;
      } else {
        if (refresh) await _cache.removeFile(source.url!);
        final file = await _cache
            .getSingleFile(source.url!)
            .timeout(const Duration(seconds: 45));
        bytes = await _readFile(file);
      }
    }
    if (bytes.length > _maxBytes) {
      throw const FormatException('This PDF is too large to open.');
    }
    // Reject login/error HTML instead of passing it to the native renderer.
    final header = String.fromCharCodes(bytes.take(1024));
    if (!header.contains('%PDF-')) {
      throw const FormatException('This link did not return a PDF.');
    }
    return bytes;
  }

  Future<Uint8List> _readFile(File file) async {
    if (await file.length() > _maxBytes) {
      throw const FormatException('This PDF is too large to open.');
    }
    return file.readAsBytes();
  }
}
