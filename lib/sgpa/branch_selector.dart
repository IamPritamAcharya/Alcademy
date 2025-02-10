import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:url_launcher/url_launcher.dart';
import 'subject_grade_input.dart';
import 'data.dart';

class BranchSelector extends StatefulWidget {
  const BranchSelector({Key? key}) : super(key: key);

  @override
  _BranchSelectorState createState() => _BranchSelectorState();
}

class _BranchSelectorState extends State<BranchSelector> {
  String? selectedBranch;
  String? selectedSemester;

  @override
  Widget build(BuildContext context) {
    final branches = subjectCreditMap.keys.toList();

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
          title: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Text(
                  'SGPA Calculator',
                  style: const TextStyle(
                    fontFamily: 'ProductSans',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.white),
              onPressed: () async {
                const url =
                    'https://drive.google.com/file/d/1MpOBukzyyM4qUGhZUt0MzV6gmhaA1ppB/view?usp=sharing';
                if (await canLaunch(url)) {
                  await launch(url);
                } else {
                  throw 'Could not launch $url';
                }
              },
            ),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Branch',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'ProductSans',
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField2<String>(
                value: selectedBranch,
                isExpanded: true,
                dropdownStyleData: DropdownStyleData(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2F30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  filled: true,
                  fillColor: Colors.grey[850],
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.greenAccent,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                hint: const Text(
                  'Select Branch',
                  style: TextStyle(
                      color: Colors.white54, fontFamily: 'ProductSans'),
                ),
                items: branches.map((branch) {
                  return DropdownMenuItem(
                    value: branch,
                    child: Text(
                      branch,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'ProductSans',
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedBranch = value;
                    selectedSemester =
                        null; // Reset semester when branch changes
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a branch';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (selectedBranch != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Semester',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'ProductSans',
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField2<String>(
                      value: selectedSemester,
                      isExpanded: true,
                      dropdownStyleData: DropdownStyleData(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2F30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        filled: true,
                        fillColor: Colors.grey[850],
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.greenAccent,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      hint: const Text(
                        'Select Semester',
                        style: TextStyle(
                            color: Colors.white54, fontFamily: 'ProductSans'),
                      ),
                      items: subjectCreditMap[selectedBranch]!
                          .keys
                          .map((semester) {
                        return DropdownMenuItem(
                          value: semester,
                          child: Text(
                            semester,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'ProductSans',
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSemester = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a semester';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              const Spacer(),
              Center(
                child: ElevatedButton(
                  onPressed:
                      (selectedBranch != null && selectedSemester != null)
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SubjectGradeInput(
                                    branch: selectedBranch!,
                                    semester: selectedSemester!,
                                  ),
                                ),
                              );
                            }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    disabledBackgroundColor: Colors.grey[800],
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      color: const Color(0xFF1A1D1E),
                      fontSize: 16,
                      fontFamily: 'ProductSans',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
