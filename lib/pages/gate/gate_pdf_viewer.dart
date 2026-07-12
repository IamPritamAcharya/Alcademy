import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class GatePdfViewer extends StatelessWidget {
  final String url;
  final String title;

  const GatePdfViewer({
    super.key,
    required this.url,
    required this.title,
  });

  void _downloadPdf() async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      // Opening a PDF URL in the external browser natively handles downloading on Android
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'ProductSans',
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Download PDF',
            onPressed: _downloadPdf,
          ),
        ],
      ),
      body: SfPdfViewer.network(
        url,
        canShowScrollHead: false,
        canShowScrollStatus: false,
      ),
    );
  }
}
