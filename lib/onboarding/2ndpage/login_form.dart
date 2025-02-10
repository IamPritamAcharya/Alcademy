import 'package:flutter/material.dart';
import 'api_service.dart';
import 'dropdown_widget.dart';

class LoginForm extends StatefulWidget {
  final VoidCallback onNextPressed;

  const LoginForm({required this.onNextPressed, Key? key}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedBranch;
  String? _selectedNote;
  List<Map<String, String>> _availableNotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final notes = await ApiService.fetchAvailableNotes();
      setState(() => _availableNotes = notes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to load notes. Please try again later.'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveData() async {
    if (_nameController.text.isEmpty ||
        _selectedBranch == null ||
        _selectedNote == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill in all fields.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isLoading = true);

    await ApiService.saveUserPreferences(
      name: _nameController.text,
      branch: _selectedBranch!,
      noteUrl: _selectedNote!,
    );

    setState(() => _isLoading = false);

    widget.onNextPressed();
  }

  Widget _buildBlurredShape({
    required double size,
    required Color color,
    required double angle,
  }) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 50,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent, // Light theme background
      body: Stack(
        children: [
          // Blurred shapes for the background
          Positioned(
            top: -50,
            left: -60,
            child: _buildBlurredShape(
              size: 180,
              color: Colors.pinkAccent.withOpacity(0.2),
              angle: 30,
            ),
          ),
          Positioned(
            bottom: -70,
            right: -40,
            child: _buildBlurredShape(
              size: 220,
              color: Colors.pinkAccent.withOpacity(0.2),
              angle: -45,
            ),
          ),
          Positioned(
            top: 200,
            left: 20,
            child: _buildBlurredShape(
              size: 140,
              color: Colors.pinkAccent.withOpacity(0.25),
              angle: 15,
            ),
          ),
          Positioned(
            bottom: 100,
            right: 100,
            child: _buildBlurredShape(
              size: 160,
              color: Colors.pinkAccent.withOpacity(0.3),
              angle: -60,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.tealAccent),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Heading
                      Text(
                        'Let’s Get Started!',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ProductSans',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Fill in your details to begin your journey.',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                          fontFamily: 'ProductSans',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      // Name Input Field
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Your Name',
                          labelStyle: const TextStyle(color: Colors.black54),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.7),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: Colors.transparent),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: Colors.pinkAccent),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Branch Dropdown
                      DropdownWidget(
                        label: 'Select Your Branch',
                        items: const [
                          'Computer Science',
                          'Electronics & TC',
                          'Electrical',
                          'Mechanical',
                          'Civil',
                          'Chemical',
                          'Metallurgical',
                          'Production'
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedBranch = value),
                      ),
                      const SizedBox(height: 20),
                      // Notes Dropdown
                      DropdownWidget(
                        label: 'Select Notes',
                        items: _availableNotes
                            .map((note) => note['name']!)
                            .toList(),
                        onChanged: (value) {
                          final selectedNote = _availableNotes.firstWhere(
                              (note) => note['name'] == value,
                              orElse: () => {});
                          setState(() => _selectedNote = selectedNote['url']);
                        },
                      ),
                      const SizedBox(height: 40),
                      // Next Button
                      ElevatedButton(
                        onPressed: _saveData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
