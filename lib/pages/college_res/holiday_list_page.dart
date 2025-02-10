import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class HolidayListPage extends StatelessWidget {
  final String pdfUrl =
      'https://igitsarang.ac.in/assets/documents/notice/holidays_list_calandar-2025_1735624680.pdf';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D1E),
        elevation: 0,
        title: const Text(
          'Holiday List: 2025',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withOpacity(0.2),
            height: 1,
          ),
        ),
      ),
      backgroundColor: const Color(0xFF1A1D1E),
      body: SfPdfViewer.network(pdfUrl),
    );
  }
}
