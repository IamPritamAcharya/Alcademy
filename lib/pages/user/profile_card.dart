import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final String userName;
  final String branch;
  final File? profileImage;
  final VoidCallback onUpdateImage;
  final VoidCallback onDeleteImage;
  final VoidCallback onEditName;

  const ProfileCard({
    Key? key,
    required this.userName,
    required this.branch,
    required this.profileImage,
    required this.onUpdateImage,
    required this.onDeleteImage,
    required this.onEditName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Color(0xFF1A1D1E).withOpacity(0.6),
              Colors.grey.shade800.withOpacity(0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Image with Hero Animation
            Hero(
              tag: 'profileImageHero', // Keep the tag consistent
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: onUpdateImage,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: profileImage != null
                          ? ClipOval(
                              child: Image.file(
                                profileImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black26,
                              ),
                              child: const Icon(
                                Icons.person_outline_rounded,
                                size: 50,
                                color: Colors.white70,
                              ),
                            ),
                    ),
                  ),
                  // Delete Icon Positioned Outside
                  Positioned(
                    right: 2,
                    bottom: -5,
                    child: GestureDetector(
                      onTap: onDeleteImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Vertical Divider
            Container(
              height: 80,
              width: 1.5,
              color: Colors.white.withOpacity(0.2),
            ),

            const SizedBox(width: 16),

            // User Details and Edit Button
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Name Row with Edit Icon
                    Row(
                      children: [
                        Expanded(
                          child: AutoSizeText(
                            userName,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'ProductSans',
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: onEditName,
                          icon: const Icon(
                            Icons.edit_note_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Branch Name
                    AutoSizeText(
                      branch,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white54,
                        fontFamily: 'ProductSans',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
