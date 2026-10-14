import '../models/note_year.dart';
import 'notes_shelf_picker.dart';
import '../../profile/data/profile_repository.dart';
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

  List<NoteYear> yearLinks = [];
  String? preferredBranch;
  String? selectedYearUrl;
  bool isLoading = true;
  bool isDataFetched = false;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  Future<void> _loadCachedData() async {
    await _loadSelectedYear();
    if (mounted) await _fetchYearLinks();
  }

  Future<void> _fetchYearLinks({bool forceRefresh = false}) async {
    if (isDataFetched && !forceRefresh) return;
    try {
      final years = await _notes.getYears(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        yearLinks = years;
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
    final branch = await ProfileRepository.getUserBranch();
    if (!mounted) return;
    if (mounted) {
      setState(() {
        selectedYearUrl = url;
        preferredBranch = branch;
      });
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
          : NotesShelfPicker(
              key: ValueKey(preferredBranch),
              years: yearLinks,
              preferredBranch: preferredBranch,
              selectedUrl: selectedYearUrl,
              onRefresh: _refreshYearLinks,
              onSelected: (year) => _saveSelectedYear(year.url),
            ),
    );
  }
}
