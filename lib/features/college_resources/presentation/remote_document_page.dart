import 'package:port/shared/theme/app_style.dart';
import 'package:port/shared/widgets/app_bar_divider.dart';
import 'package:port/features/college_resources/data/document_repository.dart';
import 'package:flutter/material.dart';
import 'package:port/shared/pdf/pdf_document_page.dart';

class RemoteDocumentPage extends StatefulWidget {
  final DocumentDefinition document;
  final DocumentRepository? repository;
  const RemoteDocumentPage({
    super.key,
    required this.document,
    this.repository,
  });

  @override
  State<RemoteDocumentPage> createState() => _RemoteDocumentPageState();
}

class _RemoteDocumentPageState extends State<RemoteDocumentPage> {
  String? pdfUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    setState(() => isLoading = true);
    try {
      final url = await (widget.repository ?? DocumentRepository()).getUrl(
        widget.document,
      );
      if (!mounted) return;
      setState(() {
        pdfUrl = url;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (pdfUrl != null) {
      return PdfDocumentPage(
        title: widget.document.title,
        source: PdfDocumentSource.network(pdfUrl!),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppStyle.background,
        elevation: 0,
        title: Text(
          widget.document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 22,
            color: AppStyle.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppStyle.text),
        centerTitle: false,
        bottom: const AppBarDivider(),
      ),
      backgroundColor: AppStyle.background,
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                backgroundColor: AppStyle.muted,
                valueColor: AlwaysStoppedAnimation<Color>(AppStyle.accent),
              ),
            )
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Couldn’t load this document.'),
                  TextButton(
                    onPressed: _loadDocument,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
    );
  }
}
