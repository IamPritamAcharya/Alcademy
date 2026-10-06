import 'package:port/shared/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:port/features/onboarding/data/onboarding_repository.dart';
import 'package:port/features/onboarding/presentation/widgets/dropdown_widget.dart';

class ProfileSetupForm extends StatefulWidget {
  final VoidCallback onNextPressed;

  const ProfileSetupForm({required this.onNextPressed, super.key});

  @override
  State<ProfileSetupForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<ProfileSetupForm> {
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
      final notes = await OnboardingRepository.fetchAvailableNotes();
      if (!mounted) return;
      if (mounted) {
        setState(() => _availableNotes = notes);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load notes. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _saveData() async {
    if (_nameController.text.isEmpty ||
        _selectedBranch == null ||
        _selectedNote == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    await OnboardingRepository.saveUserPreferences(
      name: _nameController.text,
      branch: _selectedBranch!,
      noteUrl: _selectedNote!,
    );

    if (mounted) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    if (mounted) widget.onNextPressed();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              80,
              24,
              MediaQuery.viewInsetsOf(context).bottom + 40,
            ),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppStyle.accent),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Let’s Get Started!',
                        style: const TextStyle(
                          color: AppStyle.text,
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
                          color: AppStyle.muted,
                          fontSize: 16,
                          fontFamily: 'ProductSans',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: AppStyle.text),
                        decoration: InputDecoration(
                          labelText: 'Your Name',
                          labelStyle: const TextStyle(color: AppStyle.muted),
                          filled: true,
                          fillColor: AppStyle.surface,
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                            ),
                            borderRadius: AppStyle.radius,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: AppStyle.accent,
                            ),
                            borderRadius: AppStyle.radius,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                          'Production',
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedBranch = value),
                      ),
                      const SizedBox(height: 20),
                      DropdownWidget(
                        label: 'Select Notes',
                        items: _availableNotes
                            .map((note) => note['name']!)
                            .toList(),
                        onChanged: (value) {
                          final selectedNote = _availableNotes.firstWhere(
                            (note) => note['name'] == value,
                            orElse: () => {},
                          );
                          setState(() => _selectedNote = selectedNote['url']);
                        },
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _saveData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyle.accent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppStyle.radius,
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            color: AppStyle.onAccent,
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
