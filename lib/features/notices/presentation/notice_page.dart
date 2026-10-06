import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/shared/widgets/app_bar_divider.dart';
import 'package:port/shared/widgets/collection_intro.dart';
import 'package:port/shared/widgets/custom_snackbar.dart';
import 'package:port/core/network/refresh_tracker.dart';
import '../data/notice_repository.dart';
import '../models/notice.dart';
import 'pdf_view_page.dart';
import 'widgets/notice_entry.dart';

class NoticePage extends StatefulWidget {
  final NoticeRepository? repository;
  const NoticePage({super.key, this.repository});
  @override
  State<NoticePage> createState() => _NoticePageState();
}

class _NoticePageState extends State<NoticePage> {
  List<Notice> notices = [];
  bool isLoading = true;
  String? _error;
  int currentPage = 1;
  static const noticesPerPage = 10;
  late final _repository = widget.repository ?? NoticeRepository();

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
        currentPage = currentPage.clamp(
          1,
          math.max(1, (notices.length / noticesPerPage).ceil()),
        );
        isLoading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        _error = 'Notices couldn’t load. Pull down to try again.';
      });
    }
  }

  Future<void> _refresh() async {
    final allowed = await RefreshTracker.incrementRefreshCount();
    if (!mounted) return;
    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.build(isCooldown: RefreshTracker.isCooldownActive),
      );
      return;
    }
    await fetchNotices();
  }

  void _openNotice(String url) async {
    if (url.isEmpty || url == '#') return;
    if (url.toLowerCase().endsWith('.pdf')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PDFViewPage(pdfUrl: url)),
      );
    } else {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      } catch (_) {
        debugPrint('Failed to launch notice URL');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = math.max(1, (notices.length / noticesPerPage).ceil());
    final startIndex = (currentPage - 1) * noticesPerPage;
    final displayed = notices.skip(startIndex).take(noticesPerPage).toList();
    return Scaffold(
      backgroundColor: AppStyle.background,
      appBar: AppBar(
        title: const Text('Notices'),
        bottom: const AppBarDivider(),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppStyle.accent,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            12 + MediaQuery.paddingOf(context).bottom,
          ),
          itemCount: displayed.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return CollectionIntro(
                title: 'Campus dispatch.',
                eyebrow: 'THE NOTICEBOARD',
                detail: isLoading
                    ? 'Checking for college circulars…'
                    : '${notices.length} circulars · Pull down to refresh',
              );
            }
            if (index <= displayed.length) {
              final notice = displayed[index - 1];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == 1 && currentPage == 1 ? 8 : 0,
                ),
                child: NoticeEntry(
                  notice: notice,
                  number: startIndex + index,
                  featured: index == 1 && currentPage == 1,
                  onTap: () => _openNotice(notice.downloadLink),
                ),
              );
            }
            if (isLoading) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (displayed.isEmpty || _error != null) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  _error ?? 'The board is quiet. Check back for new circulars.',
                  style: const TextStyle(color: AppStyle.muted, height: 1.5),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Previous notices',
                    onPressed: currentPage > 1
                        ? () => setState(() => currentPage--)
                        : null,
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  ),
                  Expanded(
                    child: Text(
                      '$currentPage / $totalPages',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppStyle.muted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next notices',
                    onPressed: currentPage < totalPages
                        ? () => setState(() => currentPage++)
                        : null,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
