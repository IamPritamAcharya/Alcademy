import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:port/pages/notice/pdf_view_page.dart';

import '../widgets/refresh_tracker.dart';
import '../widgets/custom_snackbar.dart';

class NoticePage extends StatefulWidget {
  @override
  _NoticePageState createState() => _NoticePageState();
}

class _NoticePageState extends State<NoticePage> {
  List<Notice> notices = [];
  bool isLoading = true;
  int currentPage = 1;
  final int noticesPerPage = 10;

  String get noticeUrl {
    final currentYear = DateTime.now().year;
    return 'https://igitsarang.ac.in/notice/$currentYear';
  }

  @override
  void initState() {
    super.initState();
    fetchNotices();
  }

  Future<void> fetchNotices() async {
    try {
      final randomValue =
          Random().nextInt(100000); // Randomize to prevent caching
      final url = '$noticeUrl?random=$randomValue';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        final noticeElements =
            document.querySelectorAll('tr[id^="noticerow_"]');

        final List<Notice> fetchedNotices = noticeElements.map((element) {
          final title = element.children[0]?.text.trim() ?? 'No Title';
          final date = element.children[1]?.text.trim() ?? 'No Date';
          final downloadLink =
              element.children[2]?.querySelector('a')?.attributes['href'] ??
                  '#';

          return Notice(title: title, date: date, downloadLink: downloadLink);
        }).toList();

        setState(() {
          notices = fetchedNotices;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch notices.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _openPDF(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewPage(pdfUrl: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (notices.length / noticesPerPage).ceil();
    final startIndex = (currentPage - 1) * noticesPerPage;
    final endIndex = (startIndex + noticesPerPage).clamp(0, notices.length);
    final displayedNotices = notices.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1D1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D1E),
        elevation: 0,
        title: Text(
          'Notices',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'ProductSans',
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Divider(color: Colors.white.withOpacity(0.2), height: 1),
          Expanded(
            child: RefreshIndicator(
              backgroundColor: const Color(0xFF1A1D1E),
              color: Colors.greenAccent,
              onRefresh: () async {
                bool isRefreshAllowed =
                    await RefreshTracker.incrementRefreshCount();
                if (!isRefreshAllowed) {
                  // Show the custom SnackBar when under cooldown
                  ScaffoldMessenger.of(context).showSnackBar(
                    CustomSnackBar.build(
                      isCooldown: RefreshTracker.isCooldownActive,
                    ),
                  );
                  return;
                }

                // Proceed with refresh logic
                await fetchNotices();
              },
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        backgroundColor: Color.fromARGB(255, 195, 249, 223),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: displayedNotices.length + 1,
                      itemBuilder: (context, index) {
                        if (index < displayedNotices.length) {
                          final notice = displayedNotices[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
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
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                                child: ListTile(
                                  title: Text(
                                    notice.title,
                                    style: TextStyle(
                                      fontFamily: 'ProductSans',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Text(
                                      notice.date,
                                      style: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontSize: 14,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.open_in_browser_rounded,
                                        color: Colors.greenAccent),
                                    onPressed: () {
                                      _openPDF(notice.downloadLink);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        } else {
                          return Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.chevron_left,
                                          size: 28,
                                          color: currentPage > 1
                                              ? Colors.greenAccent
                                              : Colors.grey),
                                      onPressed: currentPage > 1
                                          ? () {
                                              setState(() {
                                                currentPage--;
                                              });
                                            }
                                          : null,
                                    ),
                                    Text(
                                      'Page $currentPage of $totalPages',
                                      style: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.chevron_right,
                                          size: 28,
                                          color: currentPage < totalPages
                                              ? Colors.greenAccent
                                              : Colors.grey),
                                      onPressed: currentPage < totalPages
                                          ? () {
                                              setState(() {
                                                currentPage++;
                                              });
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 80),
                            ],
                          );
                        }
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class Notice {
  final String title;
  final String date;
  final String downloadLink;

  Notice({required this.title, required this.date, required this.downloadLink});
}
