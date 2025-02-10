import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class PDFViewPage extends StatelessWidget {
  final String pdfUrl;

  PDFViewPage({required this.pdfUrl});

  void _downloadPDF(BuildContext context) async {
    try {
      if (await canLaunch(pdfUrl)) {
        await launch(pdfUrl);
      } else {
        throw 'Could not launch $pdfUrl';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Viewer', style: TextStyle(fontFamily: 'ProductSans')),
        actions: [
          IconButton(
            icon: Icon(Icons.downloading_rounded, color: Colors.black),
            tooltip: 'Download PDF',
            onPressed: () {
              _downloadPDF(context);
            },
          ),
          SizedBox(
            width: 5,
          )
        ],
      ),
      body: SfPdfViewer.network(
        pdfUrl,
        onDocumentLoadFailed: (details) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load PDF: ${details.error}')),
          );
        },
      ),
    );
  }
}
