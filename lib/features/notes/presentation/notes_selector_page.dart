import 'package:port/shared/widgets/app_bar_divider.dart';
import 'package:flutter/material.dart';
import 'package:port/features/notes/data/notes_repository.dart';
import 'package:port/core/network/refresh_tracker.dart';

import 'package:port/shared/widgets/custom_snackbar.dart';

class NotesSelector extends StatefulWidget {
  const NotesSelector({super.key});

  @override
  State<NotesSelector> createState() => _NotesSelectorState();
}

class _NotesSelectorState extends State<NotesSelector> {
  final _notes = NotesRepository();

  List<Map<String, String>> yearLinks = [];
  String? selectedYearUrl;
  bool isLoading = true;
  bool isDataFetched = false;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    _loadSelectedYear();
  }

  Future<void> _loadCachedData() => _fetchYearLinks();

  Future<void> _fetchYearLinks({bool forceRefresh = false}) async {
    if (isDataFetched && !forceRefresh) return;
    try {
      final years = await _notes.getYears(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        yearLinks = years.map((year) => year.toJson()).toList();
        isDataFetched = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.build(
            message: 'Error fetching data: $e', isCooldown: false),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _refreshYearLinks() async {
    bool isRefreshAllowed = await RefreshTracker.incrementRefreshCount();
    if (!isRefreshAllowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.build(
          isCooldown: true,
        ),
      );
      return;
    }
    try {
      isDataFetched = false;
      await _fetchYearLinks(forceRefresh: true);
    } catch (e) {
      debugPrint('Error during refresh: $e');
    }
  }

  Future<void> _loadSelectedYear() async {
    final url = await _notes.getSelectedYear();
    if (!mounted) return;
    if (mounted) {
      setState(() => selectedYearUrl = url);
    }
  }

  Future<void> _saveSelectedYear(String url) async {
    await _notes.selectYear(url);
    if (!mounted) return;
    if (mounted) {
      setState(() => selectedYearUrl = url);
    }
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
        bottom: const AppBarDivider(),
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
                            ? Colors.greenAccent.withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: isSelected
                              ? Colors.greenAccent
                              : Colors.white.withValues(alpha: 0.1),
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
