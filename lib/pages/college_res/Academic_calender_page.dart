import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class AcademicCalendarPage extends StatefulWidget {
  @override
  _AcademicCalendarPageState createState() => _AcademicCalendarPageState();
}

class _AcademicCalendarPageState extends State<AcademicCalendarPage> {
  String? pdfUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAcademicCalendarUrl();
  }

  Future<void> fetchAcademicCalendarUrl() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final DateTime now = DateTime.now();

      // Check if URL is already saved and not older than a month
      final String? cachedUrl = prefs.getString('academic_calendar_url');
      final String? lastUpdatedStr =
          prefs.getString('academic_calendar_last_updated');
      final DateTime? lastUpdated =
          lastUpdatedStr != null ? DateTime.tryParse(lastUpdatedStr) : null;

      if (cachedUrl != null &&
          lastUpdated != null &&
          now.difference(lastUpdated).inDays < 30) {
        // Use cached URL
        setState(() {
          pdfUrl = cachedUrl;
          isLoading = false;
        });
        return;
      }

      // Fetch new URL from GitHub
      final response = await http.get(Uri.parse(
          'https://raw.githubusercontent.com/Academia-IGIT/DATA_hub/main/academic_calender.txt'));

      if (response.statusCode == 200) {
        final String fetchedUrl = response.body.trim();

        if (fetchedUrl.isNotEmpty) {
          // Save URL and update time in SharedPreferences
          await prefs.setString('academic_calendar_url', fetchedUrl);
          await prefs.setString(
              'academic_calendar_last_updated', now.toIso8601String());

          setState(() {
            pdfUrl = fetchedUrl;
            isLoading = false;
          });
        } else {
          throw Exception('The fetched URL is empty.');
        }
      } else {
        throw Exception('Failed to fetch academic calendar URL.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle error, e.g., show a toast/snackbar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D1E),
        elevation: 0,
        title: const Text(
          'Academic Calendar',
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
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              ),
            )
          : pdfUrl != null
              ? SfPdfViewer.network(pdfUrl!)
              : Center(
                  child: Text(
                    'Failed to load data.',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
    );
  }
}
