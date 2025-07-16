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
                  const SizedBox(height: 10), 
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
                                    100, 
                                child: DropdownButtonFormField2<String>(
                                  value: selectedGrades[subject],
                                  isExpanded:
                                      false, 
                                  dropdownStyleData: DropdownStyleData(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1D1E),
                                      borderRadius: BorderRadius.circular(20),
                                    ),

                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.all(
                                        0), 
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
                                      .center, 
                                  hint: const Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Grade',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontFamily: 'ProductSans',
                                        fontSize:
                                            14, 
                                      ),
                                    ),
                                  ),
                                  items: grades.map((grade) {
                                    return DropdownMenuItem(
                                      value: grade,
                                      alignment: Alignment
                                          .center, 
                                      child: Text(
                                        grade,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'ProductSans',
                                          fontSize:
                                              14, 
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
                  const SizedBox(height: 80), 
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
                              16), 
                        ),
                        backgroundColor: const Color(0xFF1A1D1E),
                        title: const Text(
                          'SGPA Calculated!',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'ProductSans',
                            fontSize:
                                20, 
                            fontWeight:
                                FontWeight.bold, 
                          ),
                          textAlign: TextAlign
                              .center, 
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize
                              .min, 
                          children: [
                            const SizedBox(
                                height:
                                    12), 
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
                                    24, 
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        actionsAlignment: MainAxisAlignment
                            .center, 
                        actions: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.greenAccent, 
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    12), 
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12), 
                            ),
                            child: const Text(
                              'OK',
                              style: TextStyle(
                                color: Colors.black, 
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
