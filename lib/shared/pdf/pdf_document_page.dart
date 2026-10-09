import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_style.dart';
import '../widgets/app_bar_divider.dart';
import 'pdf_document_repository.dart';
import 'pdf_document_source.dart';
import 'pdfrx_document_view.dart';

export 'pdf_document_source.dart';

typedef PdfViewBuilder =
    Widget Function(Uint8List bytes, String sourceName, VoidCallback retry);

/// Shared reader shell: navigation, loading, retry, download and share are
/// independent of the rendering engine in pdfrx_document_view.dart.
class PdfDocumentPage extends StatefulWidget {
  final PdfDocumentSource source;
  final String title;
  final PdfDocumentRepository? repository;
  final PdfViewBuilder? viewBuilder;
  const PdfDocumentPage({
    super.key,
    required this.source,
    this.title = 'Document',
    this.repository,
    this.viewBuilder,
  });

  @override
  State<PdfDocumentPage> createState() => _PdfDocumentPageState();
}

class _PdfDocumentPageState extends State<PdfDocumentPage> {
  Uint8List? _bytes;
  String? _error;
  bool _actionBusy = false;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PdfDocumentPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.source != oldWidget.source) _load();
  }

  Future<void> _load({bool refresh = false}) async {
    final attempt = ++_attempt;
    setState(() {
      _bytes = null;
      _error = null;
    });
    try {
      final bytes = await (widget.repository ?? PdfDocumentRepository()).load(
        widget.source,
        refresh: refresh,
      );
      if (mounted && attempt == _attempt) setState(() => _bytes = bytes);
    } catch (error) {
      if (mounted && attempt == _attempt) {
        setState(
          () => _error = error is FormatException
              ? error.message
              : 'Couldn’t load this PDF. Check your connection and try again.',
        );
      }
    }
  }

  Future<void> _export({required bool share}) async {
    if (_bytes == null || _actionBusy) return;
    setState(() => _actionBusy = true);
    final fileName = PdfDocumentSource.fileName(widget.title);
    try {
      if (share) {
        final box = context.findRenderObject() as RenderBox?;
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                _bytes!,
                mimeType: 'application/pdf',
                name: fileName,
              ),
            ],
            fileNameOverrides: [fileName],
            sharePositionOrigin: box == null
                ? null
                : box.localToGlobal(Offset.zero) & box.size,
          ),
        );
      } else {
        final saved = await FilePicker.saveFile(
          fileName: fileName,
          bytes: _bytes!,
          mimeType: 'application/pdf',
          dialogTitle: 'Save PDF',
        );
        if (mounted && saved != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('PDF saved.')));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              share ? 'Couldn’t share this PDF.' : 'Couldn’t save this PDF.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppStyle.background,
    appBar: AppBar(
      centerTitle: false,
      title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      bottom: const AppBarDivider(),
      actions: [
        IconButton(
          tooltip: 'Download PDF',
          onPressed: _bytes == null || _actionBusy
              ? null
              : () => _export(share: false),
          icon: const Icon(Icons.download_outlined),
        ),
        IconButton(
          tooltip: 'Share PDF',
          onPressed: _bytes == null || _actionBusy
              ? null
              : () => _export(share: true),
          icon: const Icon(Icons.ios_share_outlined),
        ),
      ],
    ),
    body: _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 36,
                    color: AppStyle.muted,
                  ),
                  const SizedBox(height: 16),
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: () => _load(refresh: true),
                    child: const Text('Retry'),
                  ),
                  if (widget.source.url != null)
                    TextButton(
                      onPressed: () async {
                        try {
                          if (await launchUrl(
                            Uri.parse(widget.source.url!),
                            mode: LaunchMode.externalApplication,
                          )) {
                            return;
                          }
                        } catch (_) {}
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Couldn’t open this link.'),
                            ),
                          );
                        }
                      },
                      child: const Text('Open in browser'),
                    ),
                ],
              ),
            ),
          )
        : _bytes == null
        ? const Center(child: CircularProgressIndicator())
        : (widget.viewBuilder ??
              (bytes, name, retry) => PdfDocumentView(
                bytes: bytes,
                sourceName: name,
                onRetry: retry,
              ))(
            _bytes!,
            widget.source.url ?? widget.source.filePath ?? widget.title,
            () => _load(refresh: true),
          ),
  );
}
