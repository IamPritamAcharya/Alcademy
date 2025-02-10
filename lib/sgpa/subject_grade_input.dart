import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'data.dart';
import 'sgpa_calculator.dart';

class SubjectGradeInput extends StatefulWidget {
  final String branch;
  final String semester;

  const SubjectGradeInput(
      {Key? key, required this.branch, required this.semester})
      : super(key: key);

  @override
  _SubjectGradeInputState createState() => _SubjectGradeInputState();
}

class _SubjectGradeInputState extends State<SubjectGradeInput> {
  final List<String> grades = ['O', 'E', 'A', 'B', 'C', 'D', 'M'];
  Map<String, String> selectedGrades = {};

  @override
  Widget build(BuildContext context) {
    final subjects = subjectCreditMap[widget.branch]?[widget.semester] ?? [];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFF1A1D1E),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Center(
            child: Text(
              widget.semester,
              style: const TextStyle(
                fontFamily: 'ProductSans',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          actions: [
            Container(width: 48),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFF444444),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 27, 27, 27),
              Color(0xFF1A1D1E),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  const SizedBox(height: 10), // Top spacer
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                      children: subjects.map((subjectData) {
                        final subject = subjectData['subject'];
                        final credit = subjectData['credit'];

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey[700]!),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subject,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'ProductSans',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Credit: $credit',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontFamily: 'ProductSans',
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width:
                                    100, // Reduce the width to make the dropdown smaller
                                child: DropdownButtonFormField2<String>(
                                  value: selectedGrades[subject],
                                  isExpanded:
                                      false, // Ensure dropdown doesn't stretch unnecessarily
                                  dropdownStyleData: DropdownStyleData(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1D1E),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
// Set a max height for dropdown
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.all(
                                        0), // Remove padding for better alignment
                                    filled: true,
                                    fillColor: Colors.grey[850],
                                    enabledBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.grey[700]!),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: Colors.greenAccent),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  alignment: Alignment
                                      .center, // Center-align text in the box
                                  hint: const Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Grade',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontFamily: 'ProductSans',
                                        fontSize:
                                            14, // Adjust font size to fit smaller width
                                      ),
                                    ),
                                  ),
                                  items: grades.map((grade) {
                                    return DropdownMenuItem(
                                      value: grade,
                                      alignment: Alignment
                                          .center, // Center-align dropdown items
                                      child: Text(
                                        grade,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'ProductSans',
                                          fontSize:
                                              14, // Ensure consistent font size
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedGrades[subject] = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 80), // Bottom spacer
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        width: 200,
        child: FloatingActionButton.extended(
          backgroundColor: selectedGrades.length == subjects.length
              ? Colors.greenAccent
              : Colors.grey[800],
          elevation: 0,
          onPressed: selectedGrades.length == subjects.length
              ? () {
                  double sgpa = calculateSGPA(selectedGrades, subjects);
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              16), // Rounded corners for a modern look
                        ),
                        backgroundColor: const Color(0xFF1A1D1E),
                        title: const Text(
                          'SGPA Calculated!',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'ProductSans',
                            fontSize:
                                20, // Slightly larger font for a more modern title
                            fontWeight:
                                FontWeight.bold, // Bold title for emphasis
                          ),
                          textAlign: TextAlign
                              .center, // Center the title for better alignment
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize
                              .min, // Adjust content size to fit naturally
                          children: [
                            const SizedBox(
                                height:
                                    12), // Add spacing between title and content
                            Text(
                              'Your SGPA is:',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontFamily: 'ProductSans',
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              sgpa.toStringAsFixed(2),
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontFamily: 'ProductSans',
                                fontSize:
                                    24, // Highlight SGPA value with a larger font size
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        actionsAlignment: MainAxisAlignment
                            .center, // Center-align actions for symmetry
                        actions: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.greenAccent, // Modern button color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    12), // Rounded button corners
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12), // Button padding
                            ),
                            child: const Text(
                              'OK',
                              style: TextStyle(
                                color: Colors.black, // Contrast text color
                                fontFamily: 'ProductSans',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          label: const Text(
            'Calculate SGPA',
            style: TextStyle(
              color: Color(0xFF1A1D1E),
              fontFamily: 'ProductSans',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
