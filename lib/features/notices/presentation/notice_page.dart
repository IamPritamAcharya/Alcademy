import 'dart:ui';
import 'package:flutter/material.dart';
import '../data/notice_repository.dart';
import '../models/notice.dart';
import 'package:port/features/notices/presentation/pdf_view_page.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:port/core/network/refresh_tracker.dart';
import 'package:port/shared/widgets/custom_snackbar.dart';

class NoticePage extends StatefulWidget {
  const NoticePage({super.key});

  @override
  State<NoticePage> createState() => _NoticePageState();
}

class _NoticePageState extends State<NoticePage> {
  List<Notice> notices = [];
  bool isLoading = true;
  int currentPage = 1;
  final int noticesPerPage = 10;

  final _repository = NoticeRepository();

  @override
  void initState() {
    super.initState();
    fetchNotices();
  }

  Future<void> fetchNotices() async {
    try {
      final fetchedNotices = await _repository.fetch();
      if (!mounted) return;
      setState(() {
        notices = fetchedNotices;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _openNotice(String url) async {
    if (url.isEmpty || url == '#') return;

    if (url.toLowerCase().endsWith('.pdf')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewPage(pdfUrl: url),
        ),
      );
    } else {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      } catch (e) {
        debugPrint('Failed to launch URL: $url');
      }
    }
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
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          Expanded(
            child: RefreshIndicator(
              backgroundColor: const Color(0xFF1A1D1E),
              color: Colors.greenAccent,
              onRefresh: () async {
                bool isRefreshAllowed =
                    await RefreshTracker.incrementRefreshCount();
                if (!isRefreshAllowed) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    CustomSnackBar.build(
                      isCooldown: RefreshTracker.isCooldownActive,
                    ),
                  );
                  return;
                }

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
                          return GestureDetector(
                            onTap: () => _openNotice(notice.downloadLink),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 0, sigmaY: 0),
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
                                    trailing: Icon(
                                        Icons.open_in_browser_rounded,
                                        color: Colors.greenAccent),
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
