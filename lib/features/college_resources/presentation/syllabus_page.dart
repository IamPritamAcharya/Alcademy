import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:port/shared/pdf/pdf_document_page.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/shared/widgets/app_bar_divider.dart';
import 'package:port/shared/widgets/collection_intro.dart';
import 'package:port/shared/widgets/study_selection_field.dart';

class SyllabusPage extends StatefulWidget {
  const SyllabusPage({super.key});
  @override
  State<SyllabusPage> createState() => _SyllabusPageState();
}

class _SyllabusPageState extends State<SyllabusPage> {
  Map<String, Map<String, String>> _data = {};
  List<String> _pins = [];
  String? _branch;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final raw =
          jsonDecode(await rootBundle.loadString('assets/data/syllabus.json'))
              as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _data = raw.map(
          (branch, years) =>
              MapEntry(branch, Map<String, String>.from(years as Map)),
        );
        _pins = prefs.getStringList('pinnedSyllabi') ?? [];
        _loading = false;
      });
    } catch (error) {
      debugPrint('Error loading syllabus data: $error');
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  Future<void> _togglePin(String url) async {
    setState(() {
      if (_pins.contains(url)) {
        _pins.remove(url);
      } else {
        _pins.insert(0, url);
      }
    });
    final pins = List<String>.of(_pins);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('pinnedSyllabi', pins);
  }

  void _open(String url, String title) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SyllabusViewer(url: url, title: title),
    ),
  );

  Widget _document(String branch, String year, String url, int index) {
    final pinned = _pins.contains(url);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppStyle.surface,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(url, '$branch · $year'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppStyle.cover,
                    borderRadius: BorderRadius.circular(3),
                    border: const Border(
                      left: BorderSide(color: AppStyle.paper, width: 3),
                    ),
                  ),
                  child: ExcludeSemantics(
                    child: Text(
                      '$index',
                      textScaler: TextScaler.noScaling,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: AppStyle.paper,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        year,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        branch,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppStyle.muted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Flexible(
                            child: Text(
                              'OPEN PDF',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppStyle.paper,
                                letterSpacing: 1.3,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.north_east_rounded,
                            size: 12,
                            color: AppStyle.paper,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: pinned ? 'Unpin $year' : 'Pin $year',
                  onPressed: () => _togglePin(url),
                  icon: Icon(
                    pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                    size: 20,
                    color: pinned ? AppStyle.lilac : AppStyle.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 14),
    child: Row(
      children: [
        Text(label, style: AppStyle.eyebrow),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: AppStyle.rule)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final pinnedDocs = <Widget>[];
    // A URL can be shared by several branches. Show one matching document per pin.
    for (final url in _pins) {
      for (final branch in _data.entries) {
        final years = branch.value.entries.toList();
        final index = years.indexWhere((entry) => entry.value == url);
        if (index >= 0) {
          pinnedDocs.add(
            _document(branch.key, years[index].key, url, index + 1),
          );
          break;
        }
      }
    }
    final years = _data[_branch]?.entries.toList() ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Syllabus'),
        bottom: const AppBarDivider(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _failed
          ? Center(
              child: TextButton(
                onPressed: _load,
                child: const Text('Couldn’t load the syllabus. Try again'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                const CollectionIntro(
                  eyebrow: 'THE ACADEMIC COLLECTION',
                  title: 'The study shelf.',
                  detail:
                      'Find your curriculum. Pin the documents you come back to.',
                ),
                StudySelectionField(
                  label: 'Branch',
                  hint: 'Choose your branch',
                  value: _branch,
                  options: _data.keys.toList(),
                  onSelected: (branch) => setState(() => _branch = branch),
                ),
                if (pinnedDocs.isNotEmpty) ...[
                  _section('PINNED / ${pinnedDocs.length}'),
                  ...pinnedDocs,
                ],
                if (_branch != null) ...[
                  _section('CURRICULUM / ${years.length} YEARS'),
                  for (var i = 0; i < years.length; i++)
                    _document(_branch!, years[i].key, years[i].value, i + 1),
                ] else ...[
                  const SizedBox(height: 28),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Choose a branch to browse its year-wise syllabus.',
                      style: TextStyle(
                        color: AppStyle.muted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class SyllabusViewer extends StatelessWidget {
  final String url;
  final String title;
  const SyllabusViewer({
    super.key,
    required this.url,
    this.title = 'Syllabus Viewer',
  });
  @override
  Widget build(BuildContext context) =>
      PdfDocumentPage(title: title, source: PdfDocumentSource.network(url));
}
