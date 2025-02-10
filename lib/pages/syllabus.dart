import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class SyllabusPage extends StatefulWidget {
  @override
  _SyllabusPageState createState() => _SyllabusPageState();
}

class _SyllabusPageState extends State<SyllabusPage> {
  Map<String, Map<String, String>> syllabusData = {};
  String? selectedBranch;
  List<String> pinnedSyllabi = [];

  @override
  void initState() {
    super.initState();
    loadSyllabusData();
    loadPinnedSyllabi();
  }

  Future<void> loadSyllabusData() async {
    try {
      final jsonString =
          await rootBundle.loadString('lib/assets/syllabus.json');
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      setState(() {
        syllabusData = data.map((branch, years) {
          return MapEntry(
            branch,
            Map<String, String>.from(years as Map),
          );
        });
      });
    } catch (e) {
      print('Error loading syllabus data: $e');
    }
  }

  Future<void> loadPinnedSyllabi() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPins = prefs.getStringList('pinnedSyllabi') ?? [];
    setState(() {
      pinnedSyllabi = savedPins;
    });
  }

  Future<void> savePinnedSyllabi() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('pinnedSyllabi', pinnedSyllabi);
  }

  Widget buildDropdown<T>({
    required String hint,
    required List<T> items,
    required T? selectedItem,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField2<T>(
      value: selectedItem,
      isExpanded: true,
      dropdownStyleData: DropdownStyleData(
        decoration: BoxDecoration(
          color: const Color(0xFF2C2F30),
          borderRadius: BorderRadius.circular(12),
        ),
        maxHeight: 200, // Fixed height for the dropdown
      ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        filled: true,
        fillColor: const Color(0xFF2C2F30),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.greenAccent),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      hint: Text(
        hint,
        style:
            const TextStyle(color: Colors.white54, fontFamily: 'ProductSans'),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            item.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'ProductSans',
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      buttonStyleData: ButtonStyleData(
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12), // Rounded InkWell corners
        ),
      ),
    );
  }

  Widget buildPinnedList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: pinnedSyllabi.expand((url) {
        String? branch;
        String? year;
        syllabusData.forEach((b, years) {
          if (years.containsValue(url)) {
            branch = b;
            year = years.entries.firstWhere((entry) => entry.value == url).key;
          }
        });

        return [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SyllabusViewer(url: url),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2F30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$branch - $year',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.push_pin_rounded,
                          color: Colors.greenAccent),
                      onPressed: () {
                        setState(() {
                          pinnedSyllabi.remove(url);
                          savePinnedSyllabi();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(
            color: Colors.white24,
            thickness: 1.0,
            height: 20,
          ),
        ];
      }).toList(),
    );
  }

  Widget buildSyllabusList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: syllabusData[selectedBranch]!.entries.map((entry) {
        final year = entry.key;
        final url = entry.value;
        final isPinned = pinnedSyllabi.contains(url);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SyllabusViewer(url: url),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2F30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$selectedBranch - $year',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isPinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      color: Colors.greenAccent,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isPinned) {
                          pinnedSyllabi.remove(url);
                        } else {
                          pinnedSyllabi.insert(0, url);
                        }
                        savePinnedSyllabi();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D1E),
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF1A1D1E),
        title: const Text(
          'Syllabus',
          style: const TextStyle(
              fontFamily: 'ProductSans',
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 3),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withOpacity(0.2),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildPinnedList(),
            const SizedBox(height: 16),
            buildDropdown<String>(
              hint: 'Select Branch',
              items: syllabusData.keys.toList(),
              selectedItem: selectedBranch,
              onChanged: (value) {
                setState(() {
                  selectedBranch = value;
                });
              },
            ),
            const SizedBox(height: 16),
            if (selectedBranch != null) buildSyllabusList(),
          ],
        ),
      ),
    );
  }
}

class SyllabusViewer extends StatelessWidget {
  final String url;

  const SyllabusViewer({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D1E),
        title: const Text('Syllabus Viewer'),
      ),
      body: SfPdfViewer.network(url),
    );
  }
}
