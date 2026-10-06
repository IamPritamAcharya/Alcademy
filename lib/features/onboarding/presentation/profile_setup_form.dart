import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/features/onboarding/data/onboarding_repository.dart';
import 'widgets/dropdown_widget.dart';
import 'widgets/onboarding_intro.dart';

class ProfileSetupForm extends StatefulWidget {
  final VoidCallback onNextPressed;
  const ProfileSetupForm({required this.onNextPressed, super.key});

  @override
  State<ProfileSetupForm> createState() => _ProfileSetupFormState();
}

class _ProfileSetupFormState extends State<ProfileSetupForm> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedBranch;
  String? _selectedNote;
  List<Map<String, String>> _availableNotes = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _loadFailed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final notes = await OnboardingRepository.fetchAvailableNotes();
      if (!mounted) return;
      setState(() {
        _availableNotes = notes;
        _loadFailed = notes.isEmpty;
      });
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveData() async {
    if (_isSaving) return;
    if (_nameController.text.trim().isEmpty ||
        _selectedBranch == null ||
        _selectedNote == null) {
      setState(() => _error = 'Add your name, branch and notes to continue.');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await OnboardingRepository.saveUserPreferences(
        name: _nameController.text.trim(),
        branch: _selectedBranch!,
        noteUrl: _selectedNote!,
      );
      if (mounted) widget.onNextPressed();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Couldn’t save your setup. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _label(String number, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Text(number, style: AppStyle.eyebrow.copyWith(color: AppStyle.accent)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppStyle.text,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(26, 30, 26, 14),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'THE FINAL TOUCH',
                            style: AppStyle.eyebrow,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppStyle.rule),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Just you.',
                            style: TextStyle(
                              color: AppStyle.paper,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'A little more\nyou.',
                      style: TextStyle(
                        fontSize: 46,
                        height: 1.05,
                        letterSpacing: -1.8,
                        fontWeight: FontWeight.bold,
                        color: AppStyle.text,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Make room for your name, your branch and what you’re learning.',
                      style: TextStyle(
                        color: AppStyle.muted,
                        height: 1.5,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _label('01', 'What should we call you?'),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(color: AppStyle.text),
                      decoration: InputDecoration(
                        hintText: 'Your name',
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          size: 21,
                          color: AppStyle.muted,
                        ),
                        filled: true,
                        fillColor: AppStyle.surface,
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppStyle.rule),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppStyle.paper),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _label('02', 'Your branch'),
                    DropdownWidget(
                      label: 'Choose your branch',
                      value: _selectedBranch,
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
                    const SizedBox(height: 24),
                    _label('03', 'Your study shelf'),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(18),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppStyle.paper,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Finding your notes…',
                                style: TextStyle(color: AppStyle.muted),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_loadFailed)
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Your notes couldn’t load.',
                              style: TextStyle(color: AppStyle.muted),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadNotes,
                            child: const Text('Retry'),
                          ),
                        ],
                      )
                    else
                      DropdownWidget(
                        label: 'Choose your notes',
                        value: _availableNotes
                            .where((note) => note['url'] == _selectedNote)
                            .firstOrNull?['name'],
                        items: _availableNotes
                            .map((note) => note['name']!)
                            .toList(),
                        onChanged: (value) => setState(
                          () => _selectedNote = _availableNotes.firstWhere(
                            (note) => note['name'] == value,
                          )['url'],
                        ),
                      ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
        OnboardingFooter(
          label: _isSaving ? 'Setting things up…' : 'Enter Alcademy',
          onPressed: _isSaving || _isLoading || _loadFailed ? null : _saveData,
          helper: _error ?? 'You can change these anytime in your profile.',
          helperColor: _error == null ? AppStyle.muted : AppStyle.danger,
        ),
      ],
    ),
  );
}
