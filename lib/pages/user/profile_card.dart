import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final String userName;
  final String branch;
  final VoidCallback onEditName;

  const ProfileCard({
    Key? key,
    required this.userName,
    required this.branch,
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
            const SizedBox(width: 16),
            Container(
              height: 80,
              width: 1.5,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AutoSizeText(
                            userName,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 24,
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
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    AutoSizeText(
                      branch,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 16,
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
