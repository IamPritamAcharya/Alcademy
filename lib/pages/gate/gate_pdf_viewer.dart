import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class GatePdfViewer extends StatelessWidget {
  final String url;
  final String title;

  const GatePdfViewer({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1421),
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
      ),
      body: SfPdfViewer.network(
        url,
        canShowScrollHead: false,
        canShowScrollStatus: false,
        pageLayoutMode: PdfPageLayoutMode.continuous,
      ),
    );
  }
}
