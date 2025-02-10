import 'package:flutter/material.dart';

class SuccessStoryItem extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String company;
  final VoidCallback onTap;

  const SuccessStoryItem({
    required this.name,
    required this.imageUrl,
    required this.company,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(imageUrl),
      ),
      title: Text(name),
      subtitle: Text(company),
      onTap: onTap,
    );
  }
}
