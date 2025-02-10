import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'widgets/refresh_tracker.dart';

import 'widgets/custom_snackbar.dart'; // Import CustomSnackBar

class YearPage extends StatefulWidget {
  @override
  _YearPageState createState() => _YearPageState();
}

class _YearPageState extends State<YearPage> {
  final String githubApiUrl =
      'https://api.github.com/repos/Academia-IGIT/DATA_hub/contents/Notes';

  List<Map<String, String>> yearLinks = [];
  String? selectedYearUrl;
  bool isLoading = true;
  bool isDataFetched = false; // Flag to prevent unnecessary fetching

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    _loadSelectedYear();
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cachedYearLinks');
    if (cachedData != null) {
      try {
        final List<dynamic> jsonData = json.decode(cachedData);
        setState(() {
          yearLinks = jsonData
              .map((item) => {
                    'name': item['name'].toString(),
                    'url': item['url'].toString(),
                  })
              .toList();
        });
        isDataFetched = true; // Mark data as fetched from cache
        isLoading = false; // Stop showing the loading indicator
      } catch (e) {
        print('Error parsing cached data: $e');
      }
    } else {
      // If no cached data is found, fetch it from the API
      _fetchYearLinks();
    }
  }

  Future<void> _cacheData(List<Map<String, String>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cachedYearLinks', json.encode(data));
  }

  Future<void> _fetchYearLinks() async {
    if (isDataFetched)
      return; // Avoid fetching again if data is already fetched

    try {
      final response = await http.get(Uri.parse(githubApiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Map<String, String>> fetchedLinks = data
            .where((file) => file['name'].endsWith('.json'))
            .map((file) => {
                  'name': file['name'].toString().replaceAll('.json', ''),
                  'url': file['download_url'].toString(),
                })
            .toList();

        if (!listEquals(yearLinks, fetchedLinks)) {
          await _cacheData(fetchedLinks);
          setState(() {
            yearLinks = fetchedLinks;
          });
        }
        isDataFetched = true; // Mark data as fetched from API
      } else {
        throw Exception('Failed to fetch year links.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.build(
          message: 'Error fetching data: $e',
          isCooldown: false,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refreshYearLinks() async {
    bool isRefreshAllowed = await RefreshTracker.incrementRefreshCount();
    if (!isRefreshAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.build(
          isCooldown: true,
        ),
      );
      return;
    }
    try {
      isDataFetched = false; // Allow fresh data fetch on refresh
      await _fetchYearLinks();
    } catch (e) {
      print('Error during refresh: $e');
    }
  }

  Future<void> _loadSelectedYear() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedYearUrl = prefs.getString('selectedYearUrl');
    });
  }

  Future<void> _saveSelectedYear(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedYearUrl', url);
    setState(() {
      selectedYearUrl = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Select Your Notes',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'ProductSans',
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
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.greenAccent,
                backgroundColor: Color(0xFF1A1D1E),
              ),
            )
          : RefreshIndicator(
              backgroundColor: const Color(0xFF1A1D1E),
              color: Colors.greenAccent,
              onRefresh: _refreshYearLinks,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: yearLinks.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 25),
                      child: const Text(
                        'Tip: After selecting an item, pull to refresh on the home page to update notes.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          fontFamily: 'ProductSans',
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final year = yearLinks[index - 1];
                  final isSelected = selectedYearUrl == year['url'];

                  return GestureDetector(
                    onTap: () async {
                      await _saveSelectedYear(year['url']!);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: isSelected
                            ? Colors.greenAccent.withOpacity(0.1)
                            : Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color: isSelected
                              ? Colors.greenAccent
                              : Colors.white.withOpacity(0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 24,
                          ),
                          leading: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color:
                                isSelected ? Colors.greenAccent : Colors.white,
                            size: 20,
                          ),
                          title: Text(
                            year['name']!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'ProductSans',
                              color: isSelected
                                  ? Colors.greenAccent
                                  : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
