import 'package:port/shared/widgets/editorial_list_row.dart';
import 'package:port/shared/widgets/collection_intro.dart';
import 'package:port/shared/theme/app_style.dart';
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
          message: 'Error fetching data: $e',
          isCooldown: false,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _refreshYearLinks() async {
    bool isRefreshAllowed = await RefreshTracker.incrementRefreshCount();
    if (!isRefreshAllowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(CustomSnackBar.build(isCooldown: true));
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
      backgroundColor: AppStyle.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Select Your Notes',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 22,
            color: AppStyle.text,
            fontWeight: FontWeight.bold,
            fontFamily: 'ProductSans',
          ),
        ),
        iconTheme: const IconThemeData(color: AppStyle.text),
        centerTitle: false,
        bottom: const AppBarDivider(),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppStyle.accent,
                backgroundColor: AppStyle.background,
              ),
            )
          : RefreshIndicator(
              backgroundColor: AppStyle.background,
              color: AppStyle.accent,
              onRefresh: _refreshYearLinks,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                itemCount: yearLinks.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const CollectionIntro(
                      title: 'Choose your year.',
                      eyebrow: 'THE STUDY SHELF',
                      detail: 'Find the resources for your current year.',
                    );
                  }

                  final year = yearLinks[index - 1];
                  final isSelected = selectedYearUrl == year['url'];

                  return Semantics(
                    selected: isSelected,
                    child: EditorialListRow(
                      number: index,
                      title: year['name']!,
                      category: isSelected ? 'Selected year' : 'Study year',
                      accent: isSelected ? AppStyle.accent : AppStyle.muted,
                      trailing: Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected ? AppStyle.accent : AppStyle.muted,
                          size: 22,
                        ),
                      ),
                      onTap: () => _saveSelectedYear(year['url']!),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
