import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:port/config.dart';
import 'package:port/forums/post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:port/forums/database_service.dart';
import 'package:port/forums/post_detail_page.dart'; // Import PostDetailPage

final supabase = Supabase.instance.client;

// Configurable limits
const int titleLimit = 30;
const int descriptionLimit = 2500;

// Default image URLs with names
const Map<String, String> defaultImageUrls = {
  'Default Image 1':
      'https://scontent.fbbi1-2.fna.fbcdn.net/v/t39.30808-6/301840587_175347228358991_4015115807765160420_n.jpg?_nc_cat=108&ccb=1-7&_nc_sid=cc71e4&_nc_ohc=xoXWQjbwAN4Q7kNvgH4bHHq&_nc_zt=23&_nc_ht=scontent.fbbi1-2.fna&_nc_gid=AJWjPrh9DZFNgIo6sM4hM21&oh=00_AYBnWdhEkMN_8RVeHzTy-Rod4uh-4sC3AGAUJgE1NmK2QA&oe=6787FFB6',
  'Default Image 2':
      'https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/c83c004e-1370-4756-88e5-4071de797088/dgdq8br-09cc7ad6-a021-47a5-b0e0-917b12b0f7a7.gif?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7InBhdGgiOiJcL2ZcL2M4M2MwMDRlLTEzNzAtNDc1Ni04OGU1LTQwNzFkZTc5NzA4OFwvZGdkcThici0wOWNjN2FkNi1hMDIxLTQ3YTUtYjBlMC05MTdiMTJiMGY3YTcuZ2lmIn1dXSwiYXVkIjpbInVybjpzZXJ2aWNlOmZpbGUuZG93bmxvYWQiXX0.tqRMtE-b2QiI2nnefNxSDMJvZCcYqFmq2ccg_Xfzqb8',
  'Default Image 3':
      'https://media.istockphoto.com/id/2169042569/photo/back-to-school-a-cat-student-in-a-cap-and-mantle-on-yellow-background-with-a-blackboard-and.jpg?s=612x612&w=0&k=20&c=Cp0dymm6Bzyp5znEZQ0zYRLTQ5v4QunN6K4tEcE7MiM=',
};

class AddPostPage extends StatefulWidget {
  const AddPostPage({Key? key}) : super(key: key);

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isViewing = false; // Tab state
  String? _errorMessage;

  Future<bool> _isValidImageUrl(String url) async {
    try {
      final image = NetworkImage(url);
      final completer = Completer<void>();
      image.resolve(const ImageConfiguration()).addListener(
            ImageStreamListener(
              (info, _) => completer.complete(),
              onError: (error, stackTrace) => completer.completeError(error),
            ),
          );
      await completer.future;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> addPost() async {
    if (_formKey.currentState!.validate()) {
      final description = _descriptionController.text.trim();
      final title = _titleController.text.trim();
      final imageUrl = _imageUrlController.text.trim();

      // Validate image URL
      final isImageValid = await _isValidImageUrl(imageUrl);
      if (!isImageValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid image URL.'),
          ),
        );
        return;
      }

      // Check if the user is banned
      final user = supabase.auth.currentUser;
      if (user != null && bannedEmails.contains(user.email)) {
        setState(() {
          _errorMessage = 'Your email is banned. You cannot post.';
        });
        return;
      }

      // Check for banned words
      if (_containsBannedWords(title) || _containsBannedWords(description)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Title or description contains banned words.'),
          ),
        );
        return;
      }

      // Check for description length
      if (description.length < 30) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content too short.'),
          ),
        );
        return;
      }

      if (user != null) {
        final userId = user.id;
        final userDisplayName = user.userMetadata?['full_name'];

        if (userDisplayName != null) {
          final success = await DatabaseService.addPost(
            title,
            imageUrl,
            description,
            userId,
            userDisplayName,
          );

          if (success) {
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You can only make one post per day.'),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User display name not found.')),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Please log in to add a post.';
        });
      }
    }
  }

  bool _containsBannedWords(String text) {
    return bannedWords.any((word) => text.toLowerCase().contains(word));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D1E),
      appBar: AppBar(
        title: const Text(
          'ADD PUBLIC POST',
          style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withOpacity(0.2),
            height: 1,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1D1E),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Top Tabs
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2E30),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildTab('Description', !_isViewing)),
                Expanded(child: _buildTab('View', _isViewing)),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1A1D1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child:
                    _isViewing ? _buildViewPreview() : _buildDescriptionForm(),
              ),
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => _isViewing = label == 'View'),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey(isActive),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: isActive ? Colors.white : Colors.transparent,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.black : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: _inputDecoration('Title').copyWith(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 16,
                ),
                filled: true,
                fillColor: const Color(0xFF2A2E30),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLength: titleLimit,
              validator: (value) => value!.isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _imageUrlController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: _inputDecoration('Image URL').copyWith(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 16,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF2A2E30),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Image URL is required'
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2E30),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton2(
                      customButton: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                        size: 30,
                      ),
                      items: defaultImageUrls.entries
                          .map(
                            (entry) => DropdownMenuItem<String>(
                              value: entry.value,
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      dropdownStyleData: DropdownStyleData(
                        maxHeight: 200,
                        width: 150,
                        offset: const Offset(
                            -90, -3), // Shift dropdown 50px to the left
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2E30).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(15),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _imageUrlController.text = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: _inputDecoration('Description').copyWith(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                filled: true,
                fillColor: const Color(0xFF2A2E30),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLength: descriptionLimit,
              maxLines: 10,
              validator: (value) =>
                  value!.isEmpty ? 'Description is required' : null,
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                "You can write the description in markdown format (.md)",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: addPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Add Post',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.white),
      ),
    );
  }

  Widget _buildViewPreview() {
    final post = Post(
      id: '',
      title: _titleController.text,
      imageUrl: _imageUrlController.text,
      description: _descriptionController.text,
      userId: '',
      email: '',
      createdAt: DateTime.now(),
    );
    return PostDetailPage(post: post);
  }
}
