import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class HolidayListPage extends StatefulWidget {
  @override
  _HolidayListPageState createState() => _HolidayListPageState();
}

class _HolidayListPageState extends State<HolidayListPage> {
  String? pdfUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHolidayListUrl();
  }

  Future<void> fetchHolidayListUrl() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day); // Today at 00:00:00
      
      final String? cachedUrl = prefs.getString('holiday_list_url');
      final String? lastUpdatedStr = prefs.getString('holiday_list_last_updated');
      final DateTime? lastUpdated =
          lastUpdatedStr != null ? DateTime.tryParse(lastUpdatedStr) : null;

      if (cachedUrl != null &&
          lastUpdated != null &&
          lastUpdated.isAfter(today.subtract(Duration(seconds: 1)))) {
        setState(() {
          pdfUrl = cachedUrl;
          isLoading = false;
        });
        return;
      }

      final response = await http.get(Uri.parse(
          'https://raw.githubusercontent.com/Academia-IGIT/DATA_hub/main/holiday_list.txt'));

      if (response.statusCode == 200) {
        final String fetchedUrl = response.body.trim();
        if (fetchedUrl.isNotEmpty) {
          await prefs.setString('holiday_list_url', fetchedUrl);
          await prefs.setString(
              'holiday_list_last_updated', now.toIso8601String());
          setState(() {
            pdfUrl = fetchedUrl;
            isLoading = false;
          });
        } else {
          throw Exception('The fetched URL is empty.');
        }
      } else {
        throw Exception('Failed to fetch holiday list URL.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

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